/* Preview editing is a source-range transaction, never an HTML-to-Markdown conversion. */
(function () {
  'use strict';
  var config = window.__macdownPreviewEditConfig;
  var previousEditor = window.macdownPreviewEditor;
  var retainedUI = config && config.selection && previousEditor && typeof previousEditor.elements==='function' ? previousEditor.elements() : null;
  var retainedPanel = retainedUI ? retainedUI.panel : null;
  if (previousEditor && typeof previousEditor.destroy==='function') previousEditor.destroy(!!retainedPanel);
  delete window.__macdownPreviewEditConfig;
  if (!config || !config.nodes) return;
  var panel = null, panelStyle = null, errorMessage = null, active = null, saved = null, timer = null, errorSelection = null;
  var mappedSpans = [], panelClass = 'macdown-preview-ui-' + config.token.replace(/[^a-zA-Z0-9_-]/g,''), runClass = panelClass + '-run';
  var handlers = [], rendering = false, selectingWithMouse = false;
  var calloutTypes = ['note','tip','warning','important','caution'];
  function listen(target, name, fn) {
    target.addEventListener(name, fn, false);
    handlers.push([target, name, fn]);
  }
  function send(payload) {
    payload.token = config.token;
    window.location.href = 'x-macdown-preview://edit/?payload=' + encodeURIComponent(JSON.stringify(payload));
  }
  function hide() { if (panel) panel.style.display = 'none'; }
  function clearSelection() {
    clearTimeout(timer); saved=null; selectingWithMouse=false;
    window.getSelection().removeAllRanges();
    if(errorMessage){errorMessage.remove();errorMessage=null;}
    errorSelection=null; hide();
  }
  function draft() {
    if (!active || active.textContent === active._mpOriginal) return null;
    return {action:'replace', id:active._mpID, text:active.textContent, token:config.token};
  }
  function finish() {
    if (active) active.removeAttribute('contenteditable');
    active = null;
  }
  function commit() {
    var payload = draft();
    if (payload) send(payload); else finish();
  }
  function mappedSpan(id) {
    return mappedSpans.find(function(span){return span._mpID===id && span.isConnected;});
  }
  function currentSelection() {
    var selection=window.getSelection();
    if(active || !selection || selection.isCollapsed || !selection.rangeCount) return null;
    var range=selection.getRangeAt(0), matches=[], spans=[];
    // WebKit can put heading/word-selection boundaries on elements rather
    // than text nodes. Resolve the intersection without guessing source runs.
    mappedSpans.forEach(function(span){
      if(!span.isConnected) return;
      if(!range.intersectsNode(span)) return;
      var prefix=document.createRange(), start=0, end=span.textContent.length;
      prefix.selectNodeContents(span);
      if(span.contains(range.startContainer)) {
        prefix.setEnd(range.startContainer,range.startOffset); start=prefix.toString().length;
      }
      prefix.selectNodeContents(span);
      if(span.contains(range.endContainer)) {
        prefix.setEnd(range.endContainer,range.endOffset); end=prefix.toString().length;
      }
      if(end>start) {
        matches.push({id:span._mpID,start:start,end:end,text:span.textContent.substring(start,end)});
        spans.push(span);
      }
    });
    var text=range.toString();
    if(!matches.length) return null;
    if(matches.map(function(run){return run.text;}).join('')!==text) {
      // HTML inserts whitespace text nodes between blocks. Those separators
      // carry no style, but every visible character must remain source-proven.
      var root=range.commonAncestorContainer;
      if(root.nodeType===3) root=root.parentNode;
      var walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT), node;
      while((node=walker.nextNode())) {
        if(!range.intersectsNode(node)) continue;
        var start=node===range.startContainer?range.startOffset:0;
        var end=node===range.endContainer?range.endOffset:node.nodeValue.length;
        var selectedText=node.nodeValue.substring(start,end);
        if(!selectedText || spans.some(function(span){return span.contains(node);})) continue;
        if(/\S/.test(selectedText) || !/[\r\n]/.test(selectedText) ||
          node.parentElement.closest('p,h1,h2,h3,h4,h5,h6,li,pre')) return null;
        var before=null, after=null;
        spans.forEach(function(span){
          var position=span.compareDocumentPosition(node);
          if(position&4) before=span;
          else if((position&2) && !after) after=span;
        });
        var beforeBlock=before && before.closest('p,h1,h2,h3,h4,h5,h6,li,pre');
        var afterBlock=after && after.closest('p,h1,h2,h3,h4,h5,h6,li,pre');
        if(!beforeBlock || !afterBlock || beforeBlock===afterBlock) return null;
      }
    }
    return {id:matches[0].id,start:matches[0].start,end:matches[0].end,
      runs:matches.map(function(run){return {id:run.id,start:run.start,end:run.end};}),text:text};
  }
  function selectionPayload(action, value) {
    var selected=currentSelection() || ((rendering || panel.contains(document.activeElement)) ? saved : null);
    if(!selected) return null;
    var payload={action:action,id:selected.id,start:selected.start,end:selected.end,token:config.token};
    payload.runs=selected.runs; payload.text=selected.text;
    if(value !== undefined && value !== null) payload.value=value;
    return payload;
  }
  function command(action, value) {
    var payload=selectionPayload(action,value);
    if(!payload) return;
    send(payload);
  }
  function button(title, action, style) {
    var b = document.createElement('button'); b.type = 'button'; b.textContent = title;
    b.setAttribute('aria-label', title);
    if(style) b.setAttribute('data-mp-style',style);
    listen(b, 'click', action); panel.appendChild(b);
    return b;
  }
  function select(label, options, action, scope) {
    var s = document.createElement('select'); s.setAttribute('aria-label', label);
    s.setAttribute('data-mp-scope',scope);
    var first = document.createElement('option'); first.textContent = label; first.value = '';
    s.appendChild(first);
    options.forEach(function (item) {
      var o = document.createElement('option'); o.textContent = item[0]; o.value = item[1]; if((item[1] === 'math-block' && !config.math) || (item[1] === 'tasks' && !config.tasks) || (item[1] === 'code-block' && !config.fenced)) o.disabled=true; s.appendChild(o);
    });
    listen(s, 'change', function () { if (s.value) action(s.value); updateStyles(saved); });
    panel.appendChild(s);
  }
  function createPanel() {
    panel = retainedPanel || document.createElement('div'); panel.id = 'macdown-preview-format';
    panel.className=panelClass;
    panel.setAttribute('data-mp-preview-ui',config.token);
    var previousStyle = retainedPanel ? retainedPanel.style.cssText : null;
    panel.textContent = '';
    panel.setAttribute('role','toolbar'); panel.setAttribute('aria-label','Mise en forme du texte sélectionné');
    panel.style.cssText = 'position:fixed;box-sizing:border-box;display:none;z-index:2147483647;background:#292929;color:#fff;border:1px solid #666;border-radius:8px;padding:8px;box-shadow:0 4px 20px #0005;width:420px;max-width:calc(100vw - 24px);max-height:calc(100vh - 16px);overflow:auto;font:13px -apple-system,sans-serif;';
    if(previousStyle) panel.style.cssText=previousStyle;
    listen(panel,'mousedown',function(e){ if(e.target.tagName === 'BUTTON') e.preventDefault(); });
    var defaultCalloutTitles={note:'Note',tip:'Tip',warning:'Warning',important:'Important',caution:'Caution'};
    var calloutOptions=calloutTypes.map(function(type){
      var title=config.calloutTitles && config.calloutTitles[type];
      return ['Encadré — '+(typeof title==='string' && title.length ? title : defaultCalloutTitles[type]),'callout-'+type];
    });
    select('Texte normal / Bloc',[
      ['Texte normal','paragraph'],['Titre 1','h1'],['Titre 2','h2'],['Titre 3','h3'],['Titre 4','h4'],['Titre 5','h5'],['Titre 6','h6'],
      ['Liste à puces','unordered'],['Liste numérotée','ordered'],['Liste de tâches','tasks'],
      ['Citation','quote'],['Code — bloc','code-block'],['Équation — bloc','math-block']
    ],function(value){command('block',value);},'block');
    select('Encadré / Menu dépliant',[
      ['Aucun encadré','no-container']
    ].concat(calloutOptions,[
      ['Menu dépliant','toggle'],
      ['Titre dépliant 1','toggle-h1'],['Titre dépliant 2','toggle-h2'],['Titre dépliant 3','toggle-h3'],['Titre dépliant 4','toggle-h4']
    ]),function(value){command('block',value);},'container');
    button('Gras',function(){command('bold');},'bold');
    button('Italique',function(){command('italic');},'italic');
    button('Souligné',function(){command('underline');},'underline');
    if(config.strike) button('Barré',function(){command('strike');},'strike');
    button('Code',function(){command('code');},'code');
    button('Retirer les styles',function(){command('clear');});
    if(config.math) button('Équation',function(){command('math');},'math');
    button('Lien',function(){var url=window.prompt('Adresse du lien (https://…)','https://');if(url) command('link',url);},'link');
    var editButton=button('Modifier le texte',function(){
      if(!saved || (saved.runs && saved.runs.length!==1)) return;
      var span=mappedSpan(saved.id);
      if(span && span.closest('code')) return;
      hide(); if(span) begin(span);
    });
    editButton.setAttribute('data-mp-edit-text','');
    panelStyle = retainedUI ? retainedUI.style : document.createElement('style'); panelStyle.id='macdown-preview-edit-style';
    var selector='.'+panelClass;
    panelStyle.textContent=selector+' button,'+selector+' select{font:inherit;color:#fff;background:#3c3c3c;border:1px solid #666;border-radius:4px;margin:2px;padding:5px;cursor:pointer} '+selector+' button:disabled{opacity:.5;cursor:default} '+selector+' [aria-pressed="true"],'+selector+' select[data-mp-active],'+selector+' option[data-mp-active]{color:#2784DE} .'+runClass+'[contenteditable]{outline:2px solid #4385be;outline-offset:3px} @media print{'+selector+'{display:none!important}}';
    document.body.appendChild(panelStyle); document.body.appendChild(panel);
  }
  function begin(span) {
    if (active === span) return;
    if (/[\r\n]/.test(span.textContent)) { showEditError('Ce passage contient plusieurs lignes source. Modifiez-le dans l’éditeur de gauche.'); return; }
    if (active) { commit(); return; }
    active = span; hide(); saved = null;
    span._mpOriginal = span.textContent;
    span.setAttribute('contenteditable','true'); span.focus();
    var range=document.createRange(); range.selectNodeContents(span);
    var selection=window.getSelection(); selection.removeAllRanges(); selection.addRange(range);
  }
  config.nodes.forEach(function (item) {
    var node = window.__macdownPreviewEditNodes[item.node];
    if (!node || !node.parentNode || node.nodeValue !== item.text) return;
    var span=document.createElement('span'); span.setAttribute('data-mp-edit-id',String(item.id));
    span.className=runClass;
    span._mpID=item.id; span.setAttribute('title','Sélectionner pour mettre en forme ou choisir Modifier le texte.');
    node.parentNode.replaceChild(span,node); span.appendChild(node);
    mappedSpans.push(span);
    listen(span,'blur',commit);
    listen(span,'keydown',function(e){
      if(e.isComposing) return;
      if(e.key === 'Escape'){e.preventDefault();span.textContent=span._mpOriginal;active=null;span.removeAttribute('contenteditable');hide();send({action:'refresh'});}
      else if(e.key === 'Enter'){e.preventDefault();commit();}
    });
    listen(span,'beforeinput',function(e){if(e.inputType && e.inputType.indexOf('format')===0)e.preventDefault();});
    listen(span,'paste',function(e){e.preventDefault();document.execCommand('insertText',false,e.clipboardData.getData('text/plain').replace(/[\r\n]+/g,' '));});
    listen(span,'drop',function(e){e.preventDefault();});
  });
  delete window.__macdownPreviewEditNodes;
  createPanel();
  function updateStyles(selected) {
    var runs=selected ? (selected.runs || [selected]) : [];
    var spans=runs.map(function(run){return mappedSpan(run.id);});
    // Fenced code is literal block content; its structure remains editable via
    // both selectors. Inline code can itself be wrapped by emphasis or a link,
    // with those markers outside the backticks rather than inside the literal.
    var containsCodeBlock=spans.some(function(span){return !!(span && span.closest('pre'));});
    panel.querySelectorAll('button').forEach(function(control){control.disabled=containsCodeBlock;});
    var selectors={bold:'strong,b',italic:'em,i',underline:'u',strike:'del,s,strike',code:'code',link:'a[href]',math:'.MathJax,.MathJax_Display'};
    panel.querySelectorAll('[data-mp-style]').forEach(function(control){
      var style=control.getAttribute('data-mp-style'), selector=selectors[style];
      var eligible=spans.filter(function(span,index){
        return style!=='code' || (span && span.textContent.substring(runs[index].start,runs[index].end).trim().length>0);
      });
      control.setAttribute('aria-pressed',String(!containsCodeBlock && eligible.length>0 && eligible.every(function(span){return !!(span && span.closest(selector));})));
    });
    function blockType(span) {
      if(!span) return '';
      if(span.closest('pre')) return 'code-block';
      if(span.closest('.MathJax_Display')) return 'math-block';
      // A heading inside a container is still a heading. Inspect its nearest
      // content element instead of allowing the outer callout to mask it.
      var block=span.closest('h1,h2,h3,h4,h5,h6,li,blockquote,p');
      if(!block) return '';
      if(/^H[1-6]$/.test(block.tagName)) return block.tagName.toLowerCase();
      if(block.tagName==='LI' || block.tagName==='P') {
        var item=span.closest('li'), list=item && item.closest('ol,ul');
        if(item && list) {
          var task=Array.from(item.querySelectorAll('input[type="checkbox"]')).some(function(input){return input.closest('li')===item;});
          return task?'tasks':list.tagName==='OL'?'ordered':'unordered';
        }
      }
      if(span.closest('blockquote')) return 'quote';
      return block.tagName==='P'?'paragraph':'';
    }
    function containerType(span) {
      if(!span) return '';
      var container=span.closest('.mp-callout,details');
      if(!container) return 'no-container';
      if(container.tagName==='DETAILS') {
        var summary=Array.from(container.children).find(function(child){return child.tagName==='SUMMARY';});
        var heading=summary && summary.querySelector('h1,h2,h3,h4');
        return heading?'toggle-'+heading.tagName.toLowerCase():'toggle';
      }
      var type=calloutTypes.find(function(name){return container.classList.contains('mp-callout-'+name);});
      return type?'callout-'+type:'';
    }
    function updateMenu(scope, typeForSpan) {
      var common=spans.length?typeForSpan(spans[0]):'';
      if(!spans.every(function(span){return typeForSpan(span)===common;})) common='';
      var menu=panel.querySelector('select[data-mp-scope="'+scope+'"]');
      menu.querySelectorAll('option').forEach(function(option){
        if(option.value && option.value===common) option.setAttribute('data-mp-active','');
        else option.removeAttribute('data-mp-active');
      });
      var matching=common ? Array.from(menu.options).find(function(option){return option.value===common;}) : null;
      menu.selectedIndex=matching?matching.index:0;
      if(matching) menu.setAttribute('data-mp-active',''); else menu.removeAttribute('data-mp-active');
    }
    panel.querySelector('[data-mp-edit-text]').disabled=containsCodeBlock || runs.length!==1 || !!(spans[0] && spans[0].closest('code'));
    updateMenu('block',blockType);
    updateMenu('container',containerType);
  }
  function updatePanel() {
    if(active || rendering || selectingWithMouse) return;
    var selected=currentSelection();
    if(errorMessage && JSON.stringify(selected)!==errorSelection) {
      errorMessage.remove(); errorMessage=null; errorSelection=null;
    }
    if(!selected){if(!panel.contains(document.activeElement)){saved=null;hide();}return;}
    saved=selected; updateStyles(selected);
    var rect=window.getSelection().getRangeAt(0).getBoundingClientRect();
    panel.style.display='block';
    panel.style.left=Math.max(12,Math.min(rect.left,window.innerWidth-panel.offsetWidth-12))+'px';
    panel.style.top=Math.max(8,Math.min(rect.bottom+8,window.innerHeight-panel.offsetHeight-8))+'px';
  }
  listen(document,'selectionchange',function(){
    clearTimeout(timer); timer=setTimeout(updatePanel,120);
  });
  listen(document,'mousedown',function(event){
    if(event.button!==0 || panel.contains(event.target)) return;
    selectingWithMouse=true; clearTimeout(timer); saved=null; hide();
  });
  function finishMouseSelection() {
    if(!selectingWithMouse) return;
    selectingWithMouse=false; clearTimeout(timer); updatePanel();
  }
  listen(window,'mouseup',finishMouseSelection);
  listen(window,'blur',function(){
    if(!selectingWithMouse) return;
    selectingWithMouse=false; clearTimeout(timer); saved=null; hide();
  });
  listen(window,'scroll',function(){if(!rendering) updatePanel();});
  listen(window,'resize',updatePanel);
  function showEditError(text) {
    errorSelection=JSON.stringify(currentSelection() || saved);
    panel.style.display='block'; panel.style.left='12px'; panel.style.top='12px';
    if(!errorMessage){errorMessage=document.createElement('div');errorMessage.id='macdown-preview-edit-error';panel.insertBefore(errorMessage,panel.firstChild);}
    errorMessage.textContent=text;
  }
  function restoreSelection(selected) {
    if(!selected) return;
    var runs=selected.runs || [selected], spans=[];
    if(!runs.length || !runs.every(function(run){
      var span=mappedSpan(run.id);
      if(!span || !span.firstChild || span.firstChild.nodeType!==3 ||
        !Number.isInteger(run.start) || !Number.isInteger(run.end) ||
        run.start<0 || run.end>span.textContent.length || run.end<=run.start ||
        (spans.length && !(spans[spans.length-1].compareDocumentPosition(span)&4))) return false;
      spans.push(span); return true;
    })) return;
    var range=document.createRange();
    range.setStart(spans[0].firstChild,runs[0].start);
    range.setEnd(spans[spans.length-1].firstChild,runs[runs.length-1].end);
    if(selected.text!==undefined && normalizedSelectionText(range.toString())!==normalizedSelectionText(selected.text)) return;
    var selection=window.getSelection(); selection.removeAllRanges(); selection.addRange(range);
    saved=currentSelection();
    updatePanel();
  }
  function normalizedSelectionText(text) {
    return text.replace(/\r\n?/g,'\n').replace(/\n+/g,'\n');
  }
  window.macdownPreviewEditor={elements:function(){return {panel:panel,style:panelStyle,spans:mappedSpans.slice()};},clearSelection:clearSelection,prepareForRender:function(){saved=currentSelection() || saved;rendering=true;clearTimeout(timer);},draft:draft,finish:finish,selectionPayload:selectionPayload,showError:function(){
    showEditError('Modification refusée : la source a changé. Copiez votre texte, puis appuyez sur Échap pour annuler.');
  },showFormattingError:function(){
    showEditError('Mise en forme refusée : cette sélection ne peut pas être représentée correctement en Markdown. Sélectionnez un passage plus court.');
  },destroy:function(preservePanel){
    clearTimeout(timer); active=null;
    handlers.forEach(function(h){h[0].removeEventListener(h[1],h[2],false);});
    if(!preservePanel && panel && panel.parentNode) panel.parentNode.removeChild(panel);
    if(panelStyle && !preservePanel)panelStyle.remove();
  }};
  restoreSelection(config.selection);
  updatePanel();
})();
