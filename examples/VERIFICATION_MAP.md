# Verification Map (self-test, shell-only)
# feature | command | pass-signal

echoes-ok    | echo ok                | ok
exit-zero    | true                   |
always-fails | echo nope; exit 1      |
