(use-modules (ice-9 threads))
(use-modules (opencog))
(use-modules (opencog logger))

;-------------------------------------------------------------------------------
; Useful functions for the actions

; For handling things return by the fuzzy matcher
(define (pick-and-generate list-of-results)
    (if (equal? (length list-of-results) 0)
        '()
        (let* (; TODO: Should be bias according to the score
               (picked (list-ref list-of-results (random (length list-of-results))))
               ; TODO: Should use gen-sentences when new microplanner is ready
               (generated (sureal (gar picked))))
            (if (null? generated)
                ; Do it again if the chosen one can't be used to generate a sentence
                (pick-and-generate (delete! generated list-of-results))
                (begin
                    ; Get the speech act of the reply
                    (State fuzzy-reply-type
                        (car (filter (lambda (node) (string-suffix? "SpeechAct" (cog-name node)))
                            (cog-filter 'DefinedLinguisticConceptNode (cog-get-all-nodes (gar picked)))))
                    )
                    ; Get the score
                    (State fuzzy-reply-conf (gdr picked))
                    generated
                )
            )
        )
    )
)

;-------------------------------------------------------------------------------

(define (call-chatbot-eva)
    (State chatbot-eva sent-to-chatbot-eva)

    (begin-thread
        (imperative-process (get-input-sent-node))
    )
)

(define (call-fuzzy)
    (State fuzzy process-started)

    (begin-thread
        (let ((fuzzy-results (fuzzy-match-sent (get-input-sent-node) '())))
            ; No result if it's an empty ListLink
            (if (equal? (cog-arity fuzzy-results) 0)
                (State fuzzy-reply no-result)
                (let ((rtn (pick-and-generate (cog-outgoing-set fuzzy-results))))
                    (cog-extract fuzzy-results)
                    (if (null? rtn)
                        ; Could happen if none of them can be used to generate
                        ; an actual sentence
                        (State fuzzy-reply no-result)
                        (State fuzzy-reply (List (map Word (string-split rtn #\ ))))
                    )
                )
            )
            (State fuzzy process-finished)
        )
    )
)

(define (call-aiml)
    (State aiml process-started)

    (begin-thread
        (let ((aiml-resp (aiml-get-response-wl (get-input-word-list))))
            ; No result if it's a ListLink with arity 0
            (if (equal? (cog-arity aiml-resp) 0)
                (State aiml-reply no-result)
                (let ((target-rules (cog-chase-link 'MemberLink 'ImplicationLink aiml-reply-rule))
                      (target-tv (cog-tv (aiml-get-selected-rule))))
                    (State aiml-reply aiml-resp)

                    ; Update the TVs of the psi-rules that will actually execute
                    ; the "Reply" action
                    (map (lambda (r) (cog-set-tv! r target-tv)) target-rules)
                )
            )
            (State aiml process-finished)
        )
    )
)

(define (say . words)
    (define utterance (string-join (map cog-name words)))

    ; Remove those '[', ']' and '\' that may exist in the output
    ; The square brackets are sometimes generated by Link Parser (which
    ; indicates that a grammatical interpretation of the sentence is
    ; found by deleting this word in the sentence using null links)
    ; The backslash is sometimes generated by AIML rules
    ; TODO: Should actually clean up the WordNodes instead
    (set! utterance (string-filter
        (lambda (c) (not (or (char=? #\[ c) (char=? #\] c) (char=? #\\ c)))) utterance))

    (display utterance)

    ; For sending out the chatbot response via the grounded predicate defined
    ; in ros-behavior-scripting
    (catch #t
        (lambda ()
            (cog-evaluate! (Evaluation (GroundedPredicate "py: say_text") (List (Node utterance))))
        )
        (lambda (key . parameters)
            ; (display "\n(Warning: Failed to call \"py: say_text\" to send out the message.)\n")
            *unspecified*
        )
    )

    (reset-all-states)
)

(define (reply anchor)
    (let ((ans-in-words (cog-chase-link 'StateLink 'ListLink anchor)))
        (if (null? ans-in-words)
            '()
            (apply say (cog-outgoing-set (car ans-in-words)))
        )
    )
)
