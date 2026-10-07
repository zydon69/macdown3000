//
//  YAMLSerialization.m
//  YAML Serialization support by Mirek Rusin based on C library LibYAML by Kirill Simonov
//  Released under MIT License
//
//  Copyright 2010 Mirek Rusin
//  Copyright 2010 Stanislav Yudin
//

#import "YAMLSerialization.h"
#import <M13OrderedDictionary/M13OrderedDictionary.h>

NSString *const YAMLErrorDomain = @"com.github.mirek.yaml";

// Assumes NSError **error is in the current scope
#define YAML_SET_ERROR(errorCode, description, recovery) \
    if (error) \
        *error = [NSError errorWithDomain: YAMLErrorDomain \
                                     code: errorCode \
                                 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: \
                                            description, NSLocalizedDescriptionKey, \
                                            recovery, NSLocalizedRecoverySuggestionErrorKey, \
                                            nil]]

@implementation YAMLSerialization

#pragma mark Reading YAML

static int
__YAMLSerializationParserInputReadHandler (void *data, unsigned char *buffer, size_t size, size_t *size_read) {
    NSInteger outcome = [(NSInputStream *) data read: (uint8_t *) buffer maxLength: size];
    if (outcome < 0) {
        *size_read = 0;
        return NO;
    } else {
        *size_read = outcome;
        return YES;
    }
}

// Validate aliases before creating Foundation containers. Cyclic graphs cannot
// be represented safely by the recursive front-matter HTML consumer.
static BOOL YAMLNodeIsAcyclic(yaml_document_t *document, int index,
                              unsigned char *states, NSUInteger depth) {
    if (depth > 256 || states[index - 1] == 1)
        return NO;
    if (states[index - 1] == 2)
        return YES;
    states[index - 1] = 1;
    yaml_node_t *node = yaml_document_get_node(document, index);
    if (node->type == YAML_SEQUENCE_NODE) {
        for (yaml_node_item_t *item = node->data.sequence.items.start;
             item < node->data.sequence.items.top; item++)
            if (!YAMLNodeIsAcyclic(document, *item, states, depth + 1))
                return NO;
    } else if (node->type == YAML_MAPPING_NODE) {
        for (yaml_node_pair_t *pair = node->data.mapping.pairs.start;
             pair < node->data.mapping.pairs.top; pair++)
            if (!YAMLNodeIsAcyclic(document, pair->key, states, depth + 1)
                || !YAMLNodeIsAcyclic(document, pair->value, states, depth + 1))
                return NO;
    }
    states[index - 1] = 2;
    return YES;
}

// Serialize single, parsed document. Does not destroy the document.
static id YAMLImmutableObject(id object, NSMapTable *copies) {
    id existing = [copies objectForKey:object];
    if (existing)
        return existing;
    id result = object;
    if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *items = [NSMutableArray array];
        for (id item in object)
            [items addObject:YAMLImmutableObject(item, copies)];
        result = [[items copy] autorelease];
    } else if ([object isKindOfClass:[M13OrderedDictionary class]]) {
        M13MutableOrderedDictionary *items = [[[M13MutableOrderedDictionary alloc] init] autorelease];
        for (id key in object)
            [items setObject:YAMLImmutableObject([object objectForKey:key], copies)
                      forKey:YAMLImmutableObject(key, copies)];
        result = [[items copy] autorelease];
    }
    [copies setObject:result forKey:object];
    return result;
}

static id
__YAMLSerializationObjectWithYAMLDocument (yaml_document_t *document, YAMLReadOptions opt, NSError **error) {

    id root = nil;
    id *objects = nil;

    // Mutability options
    Class arrayClass = [NSMutableArray class]; // TODO: FIXME:
    Class dictionaryClass = [M13MutableOrderedDictionary class]; // TODO: FIXME:
    Class stringClass = [NSString class];
    if (opt & kYAMLReadOptionMutableContainers) {
        arrayClass = [NSMutableArray class];
        dictionaryClass = [M13MutableOrderedDictionary class];
        if ((opt & kYAMLReadOptionMutableContainersAndLeaves) == kYAMLReadOptionMutableContainersAndLeaves) {
            stringClass = [NSMutableString class];
        }
    }

    if (opt & kYAMLReadOptionStringScalars) {
        // Supported
    } else {
        YAML_SET_ERROR(kYAMLErrorInvalidOptions, @"Currently only kYAMLReadOptionStringScalars is supported", @"Serialize with kYAMLReadOptionStringScalars option");
        return nil;
    }

    yaml_node_t *node = NULL;
    yaml_node_item_t *item = NULL;
    yaml_node_pair_t *pair = NULL;

    int i = 0;

    objects = (id *) calloc(document->nodes.top - document->nodes.start, sizeof(id));
    if (objects == NULL) {
        YAML_SET_ERROR(kYAMLErrorCodeOutOfMemory,  @"Couldn't allocate memory", @"Please try to free memory and retry");
        return nil;
    }

    unsigned char *states = calloc(document->nodes.top - document->nodes.start, 1);
    BOOL acyclic = states && YAMLNodeIsAcyclic(document, 1, states, 0);
    free(states);
    if (!acyclic) {
        free(objects);
        YAML_SET_ERROR(kYAMLErrorInvalidYamlObject,
                       @"Cyclic or excessively nested YAML document",
                       @"Remove recursive aliases or reduce nesting");
        return nil;
    }

    // Create all objects, don't fill containers yet...
    for (node = document->nodes.start, i = 0; node < document->nodes.top; node++, i++) {
        switch (node->type) {
            case YAML_SCALAR_NODE:
                objects[i] = [[stringClass alloc] initWithBytes:node->data.scalar.value
                                                         length:node->data.scalar.length
                                                       encoding:NSUTF8StringEncoding];
                if (!root) root = objects[i];
                break;

            case YAML_SEQUENCE_NODE:
                objects[i] = [[arrayClass alloc] initWithCapacity: node->data.sequence.items.top - node->data.sequence.items.start];
                if (!root) root = objects[i];
                break;

            case YAML_MAPPING_NODE:
                objects[i] = [[dictionaryClass alloc] initWithCapacity: node->data.mapping.pairs.top - node->data.mapping.pairs.start];
                if (!root) root = objects[i];
                break;

            default:
                break;
        }
    }

    // Fill in containers
    for (node = document->nodes.start, i = 0; node < document->nodes.top; node++, i++) {
        switch (node->type) {
            case YAML_SEQUENCE_NODE:
                for (item = node->data.sequence.items.start; item < node->data.sequence.items.top; item++)
                    [objects[i] addObject: objects[*item - 1]];
                break;

            case YAML_MAPPING_NODE:
                for (pair = node->data.mapping.pairs.start; pair < node->data.mapping.pairs.top; pair++)
                    [objects[i] setObject: objects[pair->value - 1]
                                   forKey: objects[pair->key - 1]];
                break;

            default:
                break;
        }
    }

    // Retain the root object
    if (root != nil) {
        if (!(opt & kYAMLReadOptionMutableContainers)) {
            NSMapTable *copies = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                                     valueOptions:NSPointerFunctionsStrongMemory];
            root = YAMLImmutableObject(root, copies);
        }
        [root retain];
    }

    // Release all objects. The root object and all referenced (in containers) objects
    // will have retain count > 0
    for (node = document->nodes.start, i = 0; node < document->nodes.top; node++, i++) {
        [objects[i] release];
    }

    if (objects != NULL) {
        free(objects);
    }

    return root;
}

+ (NSMutableArray *) objectsWithYAMLStream: (NSInputStream *) stream
                                   options: (YAMLReadOptions) opt
                                     error: (NSError **) error
{
    if (error)
        *error = nil;
    if (!stream) {
        YAML_SET_ERROR(kYAMLErrorCodeParseError, @"Missing YAML stream", @"Provide a readable stream");
        return nil;
    }
    NSMutableArray *documents = [NSMutableArray array];
    yaml_parser_t parser;
    memset(&parser, 0, sizeof(parser));
    if (!yaml_parser_initialize(&parser)) {
        YAML_SET_ERROR(kYAMLErrorCodeParserInitializationFailed, @"Cannot initialize YAML parser", @"Retry parsing");
        return nil;
    }
    [stream open];
    yaml_parser_set_input(&parser, __YAMLSerializationParserInputReadHandler, (void *)stream);
    BOOL succeeded = YES;
    for (;;) {
        yaml_document_t document;
        if (!yaml_parser_load(&parser, &document)) {
            YAML_SET_ERROR(kYAMLErrorCodeParseError, @"Parse error", @"Make sure YAML file is well formed");
            succeeded = NO;
            break;
        }
        BOOL done = !yaml_document_get_root_node(&document);
        if (!done) {
            id object = __YAMLSerializationObjectWithYAMLDocument(&document, opt, error);
            if (object) {
                [documents addObject:object];
                [object release];
            } else {
                succeeded = NO;
            }
        }
        yaml_document_delete(&document);
        if (done || !succeeded)
            break;
    }
    yaml_parser_delete(&parser);
    [stream close];
    return succeeded ? documents : nil;
}

+ (id) objectWithYAMLStream: (NSInputStream *) stream options: (YAMLReadOptions) opt error: (NSError **) error {
    return [[self objectsWithYAMLStream: stream options: opt error: error] firstObject];
}

+ (NSMutableArray *) objectsWithYAMLData: (NSData *) data
                                 options: (YAMLReadOptions) opt
                                   error: (NSError **) error;
{
    NSMutableArray *result = nil;
    if (data != nil) {
        NSInputStream *stream = [[NSInputStream alloc] initWithData: data];
        result = [self objectsWithYAMLStream: stream options: opt error: error];
        [stream release];
    }
    return result;
}

+ (id) objectWithYAMLData: (NSData *) data options: (YAMLReadOptions) opt error: (NSError **) error {
    return [[self objectsWithYAMLData: data options: opt error: error] firstObject];
}

+ (NSMutableArray *) objectsWithYAMLString: (NSString *) string
                                   options: (YAMLReadOptions) opt
                                     error: (NSError **) error;
{
    return [self objectsWithYAMLData: [string dataUsingEncoding: NSUTF8StringEncoding]
                             options: opt
                               error: error];
}

+ (id) objectWithYAMLString: (NSString *) string options: (YAMLReadOptions) opt error: (NSError **) error {
    return [[self objectsWithYAMLString: string options: opt error: error] firstObject];
}

#pragma mark Writing YAML

static int
__YAMLSerializationEmitterOutputWriteHandler (void *data, unsigned char *buffer, size_t size) {
    size_t offset = 0;
    while (offset < size) {
        NSInteger written = [((NSOutputStream *)data) write:buffer + offset maxLength:size - offset];
        if (written <= 0)
            return NO;
        offset += written;
    }
    return YES;
}

static BOOL YAMLObjectCanBeWritten(id object, NSHashTable *ancestors, NSUInteger depth) {
    if (!object || depth > 256)
        return NO;
    if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]]
            || object == [NSNull null])
        return YES;
    BOOL dictionary = [object isKindOfClass:[NSDictionary class]]
        || [object isKindOfClass:[M13OrderedDictionary class]];
    if (!dictionary && ![object isKindOfClass:[NSArray class]])
        return NO;
    if ([ancestors containsObject:object])
        return NO;
    [ancestors addObject:object];
    BOOL valid = YES;
    for (id child in object) {
        if (!YAMLObjectCanBeWritten(child, ancestors, depth + 1)
                || (dictionary && !YAMLObjectCanBeWritten([object objectForKey:child], ancestors, depth + 1))) {
            valid = NO;
            break;
        }
    }
    [ancestors removeObject:object];
    return valid;
}

static int
__YAMLSerializationAddObject (yaml_document_t *document, id value) {
    int result = 0;
    if ([value isKindOfClass:[NSDictionary class]]
            || [value isKindOfClass:[M13OrderedDictionary class]]) {
        result = yaml_document_add_mapping(document, NULL, YAML_BLOCK_MAPPING_STYLE);
        for (id key in [value allKeys]) {
            int keyIndex = __YAMLSerializationAddObject(document, key);
            int valueIndex = __YAMLSerializationAddObject(document, [value objectForKey: key]);
            if (!result || !keyIndex || !valueIndex
                || !yaml_document_append_mapping_pair(document, result, keyIndex, valueIndex))
                return 0;
        }
    }
    else if ([value isKindOfClass: [NSArray class]]) {
        result = yaml_document_add_sequence(document, NULL, YAML_BLOCK_SEQUENCE_STYLE);
        for (id element in value) {
            int elementIndex = __YAMLSerializationAddObject(document, element);
            if (!result || !elementIndex
                || !yaml_document_append_sequence_item(document, result, elementIndex))
                return 0;
        }
    }
    else {
        NSString *string = nil;
        if ([value isKindOfClass: [NSString class]]) {
            string = value;
        } else if (value == [NSNull null]) {
            string = @"null";
        } else {
            string = [value stringValue];
        }
        NSData *utf8 = [string dataUsingEncoding:NSUTF8StringEncoding];
        result = yaml_document_add_scalar(document, NULL, (yaml_char_t *)utf8.bytes, (int)utf8.length, YAML_PLAIN_SCALAR_STYLE);
    }
    return (int) result;
}

+ (BOOL) __YAMLSerializationAddRootObjectAndEmit: (id) object emitter: (yaml_emitter_t *) emitter {
    yaml_document_t document;
    memset(&document, 0, sizeof(document));
    if (!yaml_document_initialize(&document, NULL, NULL, NULL, 0, 0))
        return NO;
    if (!__YAMLSerializationAddObject(&document, object)) {
        yaml_document_delete(&document);
        return NO;
    }
    // yaml_emitter_dump owns and deletes the document even on failure.
    return yaml_emitter_dump(emitter, &document);
}

+ (BOOL) writeObject: (id) object
        toYAMLStream: (NSOutputStream *) stream
             options: (YAMLWriteOptions) opt
               error: (NSError **) error
{
    if (error)
        *error = nil;
    NSHashTable *ancestors = [NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
    BOOL multiple = (opt & kYAMLWriteOptionMultipleDocuments) != 0;
    if (!stream || (multiple && ![object isKindOfClass:[NSArray class]])
            || !YAMLObjectCanBeWritten(object, ancestors, 0)) {
        YAML_SET_ERROR(kYAMLErrorInvalidYamlObject, @"Unsupported or recursive YAML object", @"Provide strings, numbers, arrays and dictionaries");
        return NO;
    }
    yaml_emitter_t emitter;
    memset(&emitter, 0, sizeof(emitter));
    if (!yaml_emitter_initialize(&emitter)) {
        YAML_SET_ERROR(kYAMLErrorCodeEmitterError, @"Cannot initialize YAML emitter", @"Retry writing");
        return NO;
    }
    yaml_emitter_set_encoding(&emitter, YAML_UTF8_ENCODING);
    yaml_emitter_set_output(&emitter, __YAMLSerializationEmitterOutputWriteHandler, (void *)stream);
    [stream open];
    BOOL result = yaml_emitter_open(&emitter);
    if (result && multiple) {
        for (id child in object)
            if (![self __YAMLSerializationAddRootObjectAndEmit:child emitter:&emitter]) {
                result = NO;
                break;
            }
    } else if (result) {
        result = [self __YAMLSerializationAddRootObjectAndEmit:object emitter:&emitter];
    }
    if (result)
        result = yaml_emitter_close(&emitter);
    if (!result) {
        YAML_SET_ERROR(kYAMLErrorCodeEmitterError, @"Cannot write YAML stream", @"Check stream permissions and available storage");
    }
    [stream close];
    yaml_emitter_delete(&emitter);
    return result;
}

+ (NSData *) createYAMLDataWithObject: (id) object options: (YAMLWriteOptions) opt error: (NSError **) error {
    NSData *result = nil;
    NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
    if ([self writeObject: object toYAMLStream: stream options: opt error: error])
        result = [[stream propertyForKey: NSStreamDataWrittenToMemoryStreamKey] retain];
    [stream release];
    return result;
}

+ (NSData *) YAMLDataWithObject: (id) object options: (YAMLWriteOptions) opt error: (NSError **) error {
    return [[self createYAMLDataWithObject: object options: opt error: error] autorelease];
}

+ (NSString *) createYAMLStringWithObject: (id) object options: (YAMLWriteOptions) opt error: (NSError **) error {
    return [[NSString alloc] initWithData: [self YAMLDataWithObject: object options: opt error: error]
                                 encoding: NSUTF8StringEncoding];

}

+ (NSString *) YAMLStringWithObject: (id) object options: (YAMLWriteOptions) opt error: (NSError **) error {
    return [[self createYAMLStringWithObject: object options: opt error: error] autorelease];
}

#pragma mark Deprecated

+ (NSMutableArray *) YAMLWithStream: (NSInputStream *) stream options: (YAMLReadOptions) opt error: (NSError **) error {
    return [self objectsWithYAMLStream: stream options: opt error: error];
}

+ (NSMutableArray *) YAMLWithData: (NSData *) data options: (YAMLReadOptions) opt error: (NSError **) error {
    return [self objectsWithYAMLData: data options: opt error: error];
}

+ (NSData *) dataFromYAML: (id) object options: (YAMLWriteOptions) opt error: (NSError **) error {
    return [self YAMLDataWithObject: object options: opt error: error];
}

+ (BOOL) writeYAML: (id) object toStream: (NSOutputStream *) stream options: (YAMLWriteOptions) opt error: (NSError **) error {
    return [self writeObject: object toYAMLStream: stream options: opt error: error];
}

@end
