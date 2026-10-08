/* Preview editing is a source-range transaction, never an HTML-to-Markdown conversion. */
(function () {
  'use strict';
  var config = window.__macdownPreviewEditConfig;
  var retainedPanel = config && config.selection ? document.getElementById('macdown-preview-format') : null;
  if (window.macdownPreviewEditor) window.macdownPreviewEditor.destroy(!!retainedPanel);
  delete window.__macdownPreviewEditConfig;
  if (!config || !config.nodes) return;
  var panel = null, active = null, saved = null, timer = null, errorSelection = null;
  var handlers = [], rendering = false, selectingWithMouse = false;
  function listen(target, name, fn) {
    target.addEventListener(name, fn, false);
    handlers.push([target, name, fn]);
  }
  function send(payload) {
    payload.token = config.token;
    window.location.href = 'x-macdown-preview://edit/?payload=' + encodeURIComponent(JSON.stringify(payload));
  }
  function hide() { if (panel) panel.style.display = 'none'; }
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
  function currentSelection() {
    var selection=window.getSelection();
    if(active || !selection || selection.isCollapsed || !selection.rangeCount) return null;
    var range=selection.getRangeAt(0), matches=[], spans=[];
    // WebKit can put heading/word-selection boundaries on elements rather
    // than text nodes. Resolve the intersection without guessing source runs.
    document.querySelectorAll('[data-mp-edit-id]').forEach(function(span){
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
        if(!selectedText || node.parentElement.closest('[data-mp-edit-id]')) continue;
        if(/\S/.test(selectedText) || !/[\r\n]/.test(selectedText) ||
          node.parentElement.closest('p,h1,h2,h3,h4,h5,h6,li')) return null;
        var before=null, after=null;
        spans.forEach(function(span){
          var position=span.compareDocumentPosition(node);
          if(position&4) before=span;
          else if((position&2) && !after) after=span;
        });
        var beforeBlock=before && before.closest('p,h1,h2,h3,h4,h5,h6,li');
        var afterBlock=after && after.closest('p,h1,h2,h3,h4,h5,h6,li');
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
  function select(label, options, action) {
    var s = document.createElement('select'); s.setAttribute('aria-label', label);
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
    var previousStyle = retainedPanel ? retainedPanel.style.cssText : null;
    panel.textContent = '';
    panel.setAttribute('role','toolbar'); panel.setAttribute('aria-label','Mise en forme du texte sélectionné');
    panel.style.cssText = 'position:fixed;box-sizing:border-box;display:none;z-index:2147483647;background:#292929;color:#fff;border:1px solid #666;border-radius:8px;padding:8px;box-shadow:0 4px 20px #0005;width:420px;max-width:calc(100vw - 24px);max-height:calc(100vh - 16px);overflow:auto;font:13px -apple-system,sans-serif;';
    if(previousStyle) panel.style.cssText=previousStyle;
    listen(panel,'mousedown',function(e){ if(e.target.tagName === 'BUTTON') e.preventDefault(); });
    select('Texte normal / Bloc',[
      ['Texte normal','paragraph'],['Titre 1','h1'],['Titre 2','h2'],['Titre 3','h3'],['Titre 4','h4'],
      ['Liste à puces','unordered'],['Liste numérotée','ordered'],['Liste de tâches','tasks'],
      ['Citation','quote'],['Code — bloc','code-block'],['Encadré','callout'],['Menu dépliant','toggle'],
      ['Titre dépliant 1','toggle-h1'],['Titre dépliant 2','toggle-h2'],['Titre dépliant 3','toggle-h3'],['Titre dépliant 4','toggle-h4'],
      ['Équation — bloc','math-block']
    ],function(value){command('block',value);});
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
      var span=document.querySelector('[data-mp-edit-id="'+saved.id+'"]');
      if(span && span.closest('code')) return;
      hide(); if(span) begin(span);
    });
    editButton.setAttribute('data-mp-edit-text','');
    button('Fermer',hide);
    var style = document.getElementById('macdown-preview-edit-style') || document.createElement('style'); style.id='macdown-preview-edit-style';
    style.textContent='#macdown-preview-format button,#macdown-preview-format select{font:inherit;color:#fff;background:#3c3c3c;border:1px solid #666;border-radius:4px;margin:2px;padding:5px;cursor:pointer} #macdown-preview-format button:disabled{opacity:.5;cursor:default} #macdown-preview-format [aria-pressed="true"],#macdown-preview-format select[data-mp-active],#macdown-preview-format option[data-mp-active]{color:#2784DE} [data-mp-edit-id][contenteditable]{outline:2px solid #4385be;outline-offset:3px} @media print{#macdown-preview-format{display:none!important}}';
    document.body.appendChild(style); document.body.appendChild(panel);
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
    span._mpID=item.id; span.setAttribute('title','Sélectionner pour mettre en forme ou choisir Modifier le texte.');
    node.parentNode.replaceChild(span,node); span.appendChild(node);
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
    var spans=runs.map(function(run){return document.querySelector('[data-mp-edit-id="'+run.id+'"]');});
    var selectors={bold:'strong,b',italic:'em,i',underline:'u',strike:'del,s,strike',code:'code',link:'a[href]',math:'.MathJax,.MathJax_Display'};
    panel.querySelectorAll('[data-mp-style]').forEach(function(control){
      var style=control.getAttribute('data-mp-style'), selector=selectors[style];
      var eligible=spans.filter(function(span,index){
        return style!=='code' || (span && span.textContent.substring(runs[index].start,runs[index].end).trim().length>0);
      });
      control.setAttribute('aria-pressed',String(eligible.length>0 && eligible.every(function(span){return !!(span && span.closest(selector));})));
    });
    function blockType(span) {
      if(!span) return '';
      var heading=span.closest('h1,h2,h3,h4,h5,h6'), details=span.closest('details');
      if(span.closest('.mp-callout')) return 'callout';
      if(details) return heading?'toggle-'+heading.tagName.toLowerCase():'toggle';
      if(span.closest('li') && span.closest('ol,ul')) return span.closest('li').querySelector('input[type="checkbox"]')?'tasks':span.closest('ol,ul').tagName==='OL'?'ordered':'unordered';
      if(span.closest('blockquote')) return 'quote';
      if(heading) return heading.tagName.toLowerCase();
      return span.closest('p')?'paragraph':'';
    }
    var block=spans.length?blockType(spans[0]):'';
    if(!spans.every(function(span){return blockType(span)===block;})) block='';
    panel.querySelector('[data-mp-edit-text]').disabled=runs.length!==1 || !!(spans[0] && spans[0].closest('code'));
    var menu=panel.querySelector('select');
    menu.querySelectorAll('option').forEach(function(option){
      if(option.value && option.value===block) option.setAttribute('data-mp-active','');
      else option.removeAttribute('data-mp-active');
    });
    var matching=Array.from(menu.options).find(function(option){return option.value===block;});
    menu.selectedIndex=matching?matching.index:0;
    if(matching) menu.setAttribute('data-mp-active',''); else menu.removeAttribute('data-mp-active');
  }
  function updatePanel() {
    if(active || rendering || selectingWithMouse) return;
    var selected=currentSelection();
    var message=document.getElementById('macdown-preview-edit-error');
    if(message && JSON.stringify(selected)!==errorSelection) {
      message.remove(); errorSelection=null;
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
    var message=document.getElementById('macdown-preview-edit-error');
    if(!message){message=document.createElement('div');message.id='macdown-preview-edit-error';panel.insertBefore(message,panel.firstChild);}
    message.textContent=text;
  }
  function restoreSelection(selected) {
    if(!selected) return;
    var runs=selected.runs || [selected], spans=[];
    if(!runs.length || !runs.every(function(run){
      var span=document.querySelector('[data-mp-edit-id="'+run.id+'"]');
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
  window.macdownPreviewEditor={prepareForRender:function(){saved=currentSelection() || saved;rendering=true;clearTimeout(timer);},draft:draft,finish:finish,selectionPayload:selectionPayload,showError:function(){
    showEditError('Modification refusée : la source a changé. Copiez votre texte, puis appuyez sur Échap pour annuler.');
  },showFormattingError:function(){
    showEditError('Mise en forme refusée : cette sélection ne peut pas être représentée correctement en Markdown. Sélectionnez un passage plus court.');
  },destroy:function(preservePanel){
    clearTimeout(timer); active=null;
    handlers.forEach(function(h){h[0].removeEventListener(h[1],h[2],false);});
    if(!preservePanel && panel && panel.parentNode) panel.parentNode.removeChild(panel);
    var style=document.getElementById('macdown-preview-edit-style');if(style && !preservePanel)style.remove();
  }};
  restoreSelection(config.selection);
  updatePanel();
})();
