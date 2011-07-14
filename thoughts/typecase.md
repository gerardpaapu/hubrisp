In javascript if I want to do Typecase it looks like this.

    function (val) {
        switch (Type.classify(val, Number, String, Integer)) {
            case Number:
                return 'number'; 
            break;

            case String:
                return 'string';
            break;

            case Integer:
                return 'integer';
            break;

            default:
                return 'no idea';
        }
    }

A similar thing in hubrisp would look like this:

    (fn [val]
        (case (Type.classify val Number String Integer)
            [Number 'number']
            [String 'string']
            [Integer 'integer']
            [else 'no idea']))

But with a handy dandy macro:

    (define-syntax typecase
        (syntax-rules (else) ;; this doesn't actually handle else
                             ;; because I can't remember how that works 
            [(_ exp
                [type body ...]
                ...)
             (case (Type.classify exp type ...)
                [type body ...]
                ...)]
        ))

It could look like this:

    (fn [val]
        (typecase val
            [Number 'number']
            [String 'string']
            [Integer 'integer']
            [else 'no idea']))
