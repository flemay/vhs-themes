# If ENV_ENABLE_OUTPUT_ASCII=true, record.sh will include another command "Output" to the tape file
Output "${TAPE_OUTPUT}"

Require nvim

Set Theme "${TAPE_THEME}"
Set FontSize 22
Set Padding 10
Set Width 1300
Set Height 650
Set TypingSpeed 25ms

Hide
Type "cd ${TAPE_INPUT_DIR} && clear"
Enter
Show
Type "ls -l | grep *.go"
Enter
Sleep 2s

Hide
Type "vim -O README.md main.go docker-compose.yml"
Show
Sleep 1500ms
Enter
Sleep 4s

Hide
Type ":qa!"
Enter
