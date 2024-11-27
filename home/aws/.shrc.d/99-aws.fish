# Not mentioned in the documentation, but some kind soul figured it out in aws/aws-cli#1079
complete --command aws --no-files \
    --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'
