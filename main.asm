; Personnel Management System in x86 Assembly
; UCA L3 Informatique - Project Architecture des ordinateurs

section .data
    ; Constants for data structure
    PERSON_SIZE     equ 36        ; Size of each person record in bytes
    NAME_SIZE       equ 32        ; Maximum size for name field
    NAME_OFFSET     equ 0         ; Offset of name in person record
    AGE_OFFSET      equ 32        ; Offset of age in person record
    MAX_PERSONS     equ 100       ; Maximum number of persons to store

    ; System call constants
    SYS_EXIT        equ 1         ; System call for program exit
    SYS_READ        equ 3         ; System call for reading from stdin
    SYS_WRITE       equ 4         ; System call for writing to stdout
    STDIN           equ 0         ; File descriptor for standard input
    STDOUT          equ 1         ; File descriptor for standard output

    ; Storage for personnel data
    personnel       times MAX_PERSONS * PERSON_SIZE db 0  ; Space for 100 persons (36 bytes each)
    nb_personnes    dd 0          ; Counter for number of persons stored

    ; Menu messages
    msg_menu        db 10, "1 Enregistrer du personnel", 10
                    db "2 Lister des personnes enregistrees", 10
                    db "3 Supprimer une personne specifique", 10
                    db "4 Afficher la personne la plus agee, et la personne la plus jeune", 10
                    db "5 Afficher l'age moyen de toutes les personnes enregistrees", 10
                    db "6 Quitter le programme", 10
                    db "Votre choix: ", 0
    msg_menu_len    equ $ - msg_menu

    ; Operation messages
    msg_register    db "$gewu: Enregistrement des personnes:", 10, "$gewu: ", 0
    msg_list        db "$gewu: Liste des personnes:", 10, 0
    msg_delete      db "$gewu: Suppression la personne:", 10, "$gewu: ", 0
    msg_extremes    db "$gewu: Plus agee et plus jeune:", 10, 0
    msg_average     db "$gewu: Age en moyenne:", 10, "$gewu: ", 0
    msg_goodbye     db "$gewu: Au revoir!", 10, 0

    ; Error messages
    msg_err_full    db "$gewu: Erreur: La liste est pleine!", 10, 0
    msg_err_empty   db "$gewu: Aucune personne enregistree.", 10, 0
    msg_err_invalid db "$gewu: Cette personne n'existe pas !", 10, 0
    msg_err_input   db "$gewu: Entree invalide. Format attendu: Nom Age", 10, 0
    msg_err_age     db "$gewu: Age invalide. L'age doit etre un nombre positif inferieur a 150.", 10, 0
    msg_success     db "$gewu: Personne enregistree avec succes!", 10, 0
    
    ; Delete confirmation message
    msg_delete_confirm_pre   db "$gewu: Personne ", 0
    msg_delete_confirm_post  db " a ete supprimee !", 10, 0
    
    ; Input/output buffers
    input_buffer    times 100 db 0    ; Buffer for user input
    output_buffer   times 100 db 0    ; Buffer for formatting output

    ; Formatting messages
    msg_person_prefix db "$gewu: ", 0
    msg_space       db " ", 0
    msg_newline     db 10, 0
    
    ; Messages for show_extremes function
    msg_single_person db "Une seule personne enregistree, elle est a la fois la plus agee et la plus jeune.", 10, 0
    msg_oldest      db "Plus agee: ", 0
    msg_youngest    db "Plus jeune: ", 0
    
    ; Messages for show_average function
    msg_open_paren  db "(", 0
    msg_close_paren db ")", 0

section .text
global _start

_start:
    ; Main program loop
    .menu_loop:
        ; Display menu
        call display_menu
        
        ; Get user choice
        call get_int_input
        
        ; Process choice
        cmp eax, 1
        je .option_1
        cmp eax, 2
        je .option_2
        cmp eax, 3
        je .option_3
        cmp eax, 4
        je .option_4
        cmp eax, 5
        je .option_5
        cmp eax, 6
        je .exit_program
        
        ; Invalid choice, return to menu
        jmp .menu_loop
        
    .option_1:
        ; Display register message
        mov esi, msg_register
        call print_string
        
        call register_person
        jmp .menu_loop
        
    .option_2:
        ; Display list message
        mov esi, msg_list
        call print_string
        
        call list_persons
        jmp .menu_loop
        
    .option_3:
        ; Display delete message
        mov esi, msg_delete
        call print_string
        
        call delete_person
        jmp .menu_loop
        
    .option_4:
        ; Display extremes message
        mov esi, msg_extremes
        call print_string
        
        call show_extremes
        jmp .menu_loop
        
    .option_5:
        ; Display average message
        mov esi, msg_average
        call print_string
        
        call show_average
        jmp .menu_loop
        
    .exit_program:
        ; Display goodbye message
        mov esi, msg_goodbye
        call print_string
        
        ; Exit program
        mov eax, SYS_EXIT
        xor ebx, ebx        ; Return code 0
        int 0x80

; Function: display_menu
; Description: Affiche le menu principal du programme à l'écran
display_menu:
    ; Sauvegarde le pointeur de base pour pouvoir y revenir plus tard
    push ebp
    ; Configure un nouveau cadre de pile pour isoler l'environnement de la fonction
    mov ebp, esp
    
    ; Prépare l'appel système write (code 4) pour afficher du texte
    mov eax, SYS_WRITE
    ; Indique que nous voulons écrire sur la sortie standard (écran)
    mov ebx, STDOUT
    ; Charge l'adresse du message du menu à afficher
    mov ecx, msg_menu
    ; Spécifie la longueur exacte du message pour éviter d'afficher des données indésirables
    mov edx, msg_menu_len
    ; Déclenche l'interruption pour exécuter l'appel système
    int 0x80
    
    ; Restaure le pointeur de pile pour nettoyer les variables locales
    mov esp, ebp
    ; Récupère l'ancien pointeur de base pour revenir au contexte de l'appelant
    pop ebp
    ; Retourne au code appelant pour continuer l'exécution du programme
    ret

; Function: get_int_input
; Reads an integer from user input
; Returns: EAX = integer value
get_int_input:
    push ebp
    mov ebp, esp
    
    ; Clear input buffer
    mov edi, input_buffer  ; Set EDI to point to the buffer address
    mov ecx, 100           ; Set counter to buffer size
    mov al, 0              ; Byte to store
    rep stosb              ; Fill buffer with zeros
    
    ; Read user input
    mov eax, SYS_READ
    mov ebx, STDIN
    mov ecx, input_buffer
    mov edx, 100
    int 0x80
    
    ; Convert string to integer (simple implementation)
    xor eax, eax        ; Initialize result to 0
    mov esi, input_buffer
    
    .read_digit:
        movzx ecx, byte [esi]   ; Get character
        cmp ecx, '0'            ; Check if below '0'
        jb .done
        cmp ecx, '9'            ; Check if above '9'
        ja .done
        
        ; Convert to digit and add to result
        sub ecx, '0'            ; Convert ASCII to number
        imul eax, eax, 10       ; Multiply current result by 10
        add eax, ecx            ; Add new digit
        
        inc esi                 ; Move to next character
        jmp .read_digit
        
    .done:
        mov esp, ebp
        pop ebp
        ret

; Function: print_string
; Prints a null-terminated string
; Parameters: ESI = address of string
print_string:
    push ebp
    mov ebp, esp
    
    ; Calculate string length
    mov edi, esi
    xor ecx, ecx
    not ecx                 ; Set to maximum value
    xor al, al              ; Look for null terminator
    repne scasb             ; Find end of string
    not ecx                 ; Invert count
    dec ecx                 ; Get actual length
    
    ; Print string
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov edx, ecx            ; Length
    mov ecx, esi            ; String address
    int 0x80
    
    mov esp, ebp
    pop ebp
    ret

; Function: register_person
; Registers a new person with name and age
register_person:
    push ebp
    mov ebp, esp
    sub esp, 8                  ; Allocate local variables: offset for space, age
    
    ; Check if list is full
    mov eax, [nb_personnes]
    cmp eax, MAX_PERSONS
    jl .not_full
    
    ; List is full, display error message
    mov esi, msg_err_full
    call print_string
    jmp .done
    
.not_full:
    ; Read user input (the prompt is already displayed before function call)
    mov eax, SYS_READ
    mov ebx, STDIN
    mov ecx, input_buffer
    mov edx, 100
    int 0x80
    
    ; Replace newline with null terminator
    mov esi, input_buffer
    
.find_newline:
    cmp byte [esi], 10         ; Is it a newline?
    je .replace_newline
    cmp byte [esi], 0          ; End of string?
    je .parse_input
    inc esi
    jmp .find_newline
    
.replace_newline:
    mov byte [esi], 0          ; Replace newline with null terminator
    
.parse_input:
    ; Parse input to find space separator between name and age
    mov esi, input_buffer
    xor ecx, ecx               ; ECX will track the position of the space
    
.find_space:
    cmp byte [esi], 0          ; End of string?
    je .invalid_format
    cmp byte [esi], ' '        ; Is it a space?
    je .found_space
    inc esi
    inc ecx
    jmp .find_space
    
.invalid_format:
    ; No space found, invalid format
    mov esi, msg_err_input
    call print_string
    jmp .done
    
.found_space:
    ; Space found, save position
    mov [ebp-4], ecx           ; Save space position
    mov byte [esi], 0          ; Replace space with null terminator
    inc esi                    ; Move to the first character of age
    
    ; Parse age (similar to get_int_input)
    xor eax, eax               ; EAX will store the age
    
.parse_age:
    movzx ecx, byte [esi]      ; Get next character
    cmp ecx, 0                 ; End of string?
    je .age_parsed
    cmp ecx, '0'               ; Below '0'?
    jb .invalid_age
    cmp ecx, '9'               ; Above '9'?
    ja .invalid_age
    
    ; Valid digit, convert and add to result
    sub ecx, '0'               ; Convert to number
    imul eax, eax, 10          ; Multiply current result by 10
    add eax, ecx               ; Add new digit
    
    inc esi                    ; Next character
    jmp .parse_age
    
.invalid_age:
    ; Age contains non-digit, invalid
    mov esi, msg_err_input
    call print_string
    jmp .done
    
.age_parsed:
    ; Validate age range (0-150)
    cmp eax, 0
    jl .age_out_of_range
    cmp eax, 150
    jg .age_out_of_range
    
    ; Age is valid, save it
    mov [ebp-8], eax           ; Save age
    
    ; Calculate pointer to new person record
    mov eax, [nb_personnes]
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    
    ; Copy name (input_buffer now contains just the name)
    mov esi, input_buffer
    mov edi, eax               ; Destination is start of record
    mov ecx, NAME_SIZE-1       ; Maximum name length (leaving room for null)
    
.copy_name:
    mov al, [esi]              ; Get character from source
    mov [edi], al              ; Copy to destination
    cmp al, 0                  ; End of string?
    je .name_copied
    inc esi                    ; Next source character
    inc edi                    ; Next destination position
    dec ecx                    ; Decrement counter
    jnz .copy_name             ; Continue if not zero
    
    ; Ensure name is null-terminated
    mov byte [edi], 0
    
.name_copied:
    ; Calculate pointer to age field
    mov eax, [nb_personnes]
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    add eax, AGE_OFFSET        ; Add offset to age field
    
    ; Store age
    mov edx, [ebp-8]           ; Get saved age
    mov [eax], edx             ; Store age in record
    
    ; Increment person counter
    inc dword [nb_personnes]
    
    ; Display success message
    mov esi, msg_success
    call print_string
    jmp .done
    
.age_out_of_range:
    mov esi, msg_err_age
    call print_string
    
.done:
    mov esp, ebp
    pop ebp
    ret

; Function: list_persons
; Lists all registered persons
list_persons:
    push ebp
    mov ebp, esp
    sub esp, 16                 ; Allocate local variables (index, person address, etc.)
    
    ; Check if list is empty
    mov eax, [nb_personnes]
    test eax, eax               ; Check if nb_personnes is zero
    jnz .not_empty
    
    ; List is empty, display message
    mov esi, msg_err_empty
    call print_string
    jmp .done
    
.not_empty:
    ; Initialize loop counter (person index)
    mov dword [ebp-4], 0        ; Store index in local variable
    
.loop_person:
    ; Calculate address of current person record
    mov eax, [ebp-4]            ; Get current index
    imul eax, PERSON_SIZE       ; Multiply by record size
    add eax, personnel          ; Add base address
    mov [ebp-8], eax            ; Store person address in local variable
    
    ; Prepare to print person number (index + 1)
    mov eax, [ebp-4]
    inc eax                     ; Display 1-based index to user
    
    ; Convert person number to string
    ; We'll use a small buffer on the stack
    lea edi, [ebp-16]           ; Use stack space for number conversion
    add edi, 4                  ; Start at end of buffer (4 bytes should be enough)
    mov byte [edi], 0           ; Null-terminate the string
    
    mov ebx, 10                 ; Divisor for conversion
    
.convert_number:
    dec edi                     ; Move buffer pointer
    xor edx, edx                ; Clear high bits for division
    div ebx                     ; Divide eax by 10, remainder in edx
    add dl, '0'                 ; Convert remainder to ASCII
    mov [edi], dl               ; Store digit
    test eax, eax               ; Check if quotient is zero
    jnz .convert_number         ; If not, continue conversion
    
    ; Print "$gewu: "
    mov esi, msg_person_prefix
    call print_string
    
    ; Print person number (now in edi)
    mov esi, edi
    call print_string
    
    ; Print space
    mov esi, msg_space
    call print_string
    
    ; Print person name
    mov esi, [ebp-8]            ; Load person address
    call print_string
    
    ; Print space
    mov esi, msg_space
    call print_string
    
    ; Print person age
    mov eax, [ebp-8]            ; Load person address
    add eax, AGE_OFFSET         ; Add offset to age field
    mov eax, [eax]              ; Get age value
    
    ; Convert age to string
    lea edi, [ebp-16]           ; Use stack space for age conversion
    add edi, 4                  ; Start at end of buffer
    mov byte [edi], 0           ; Null-terminate the string
    
    mov ebx, 10                 ; Divisor for conversion
    
.convert_age:
    dec edi                     ; Move buffer pointer
    xor edx, edx                ; Clear high bits for division
    div ebx                     ; Divide eax by 10, remainder in edx
    add dl, '0'                 ; Convert remainder to ASCII
    mov [edi], dl               ; Store digit
    test eax, eax               ; Check if quotient is zero
    jnz .convert_age            ; If not, continue conversion
    
    ; Print age
    mov esi, edi
    call print_string
    
    ; Print newline
    mov esi, msg_newline
    call print_string
    
    ; Increment counter and check if we've printed all persons
    inc dword [ebp-4]           ; Increment index
    mov eax, [ebp-4]            ; Load current index
    cmp eax, [nb_personnes]     ; Compare with total persons
    jl .loop_person             ; If less, continue loop
    
.done:
    mov esp, ebp
    pop ebp
    ret

; Function: delete_person
; Deletes a person with specified index
delete_person:
    push ebp
    mov ebp, esp
    sub esp, 8                  ; Allocate local variables (index, counter)
    
    ; Check if list is empty
    mov eax, [nb_personnes]
    test eax, eax               ; Check if nb_personnes is zero
    jnz .not_empty
    
    ; List is empty, display message
    mov esi, msg_err_empty
    call print_string
    jmp .done
    
.not_empty:
    ; Read user input (the prompt is already displayed before function call)
    mov eax, SYS_READ
    mov ebx, STDIN
    mov ecx, input_buffer
    mov edx, 100
    int 0x80
    
    ; Replace newline with null terminator
    mov esi, input_buffer
    
.find_newline:
    cmp byte [esi], 10         ; Is it a newline?
    je .replace_newline
    cmp byte [esi], 0          ; End of string?
    je .parse_input
    inc esi
    jmp .find_newline
    
.replace_newline:
    mov byte [esi], 0          ; Replace newline with null terminator
    
.parse_input:
    ; Convert input to integer (person number)
    mov esi, input_buffer
    xor eax, eax               ; Initialize result to 0
    
.parse_number:
    movzx ecx, byte [esi]      ; Get next character
    cmp ecx, 0                 ; End of string?
    je .number_parsed
    cmp ecx, '0'               ; Below '0'?
    jb .invalid_number
    cmp ecx, '9'               ; Above '9'?
    ja .invalid_number
    
    ; Valid digit, convert and add to result
    sub ecx, '0'               ; Convert to number
    imul eax, eax, 10          ; Multiply current result by 10
    add eax, ecx               ; Add new digit
    
    inc esi                    ; Next character
    jmp .parse_number
    
.invalid_number:
    ; Number contains non-digit, invalid
    mov esi, msg_err_invalid
    call print_string
    jmp .done
    
.number_parsed:
    ; Validate the person number (should be between 1 and nb_personnes)
    cmp eax, 1
    jl .invalid_index
    cmp eax, [nb_personnes]
    jg .invalid_index
    
    ; Store valid index (0-based) for deletion
    dec eax                    ; Convert from 1-based to 0-based
    mov [ebp-4], eax           ; Store in local variable
    
    ; Display confirmation message with person details
    ; First, print preamble
    mov esi, msg_delete_confirm_pre
    call print_string
    
    ; Print the person number (1-based)
    mov eax, [ebp-4]
    inc eax                    ; Back to 1-based for display
    
    ; Convert person number to string
    lea edi, [ebp-8]           ; Use stack space for number conversion
    add edi, 4                 ; Start at end of buffer
    mov byte [edi], 0          ; Null-terminate
    
    mov ebx, 10                ; Divisor for conversion
    
.convert_number:
    dec edi                    ; Move buffer pointer
    xor edx, edx               ; Clear high bits for division
    div ebx                    ; Divide eax by 10, remainder in edx
    add dl, '0'                ; Convert remainder to ASCII
    mov [edi], dl              ; Store digit
    test eax, eax              ; Check if quotient is zero
    jnz .convert_number        ; If not, continue conversion
    
    ; Print person number
    mov esi, edi
    call print_string
    
    ; Print space
    mov esi, msg_space
    call print_string
    
    ; Print person name
    mov eax, [ebp-4]           ; Get index
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    mov esi, eax               ; Load person name address
    call print_string
    
    ; Print confirmation message postamble
    mov esi, msg_delete_confirm_post
    call print_string
    
    ; Perform deletion by shifting subsequent records
    mov ecx, [ebp-4]           ; Current index to process
    
.shift_loop:
    ; Check if we've processed all subsequent records
    inc ecx                    ; Move to next record
    cmp ecx, [nb_personnes]    ; Compare with total records
    jge .shift_done            ; If beyond the last, we're done
    
    ; Calculate source address (record to move)
    mov eax, ecx
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address = source address
    
    ; Calculate destination address (one record back)
    mov edx, ecx
    dec edx                    ; Previous index
    imul edx, PERSON_SIZE      ; Multiply by record size
    add edx, personnel         ; Add base address = destination address
    
    ; Copy name (using a loop to copy NAME_SIZE bytes)
    push ecx                   ; Save counter
    mov ecx, NAME_SIZE         ; Copy name bytes
    mov esi, eax               ; Source
    mov edi, edx               ; Destination
    rep movsb                  ; Copy ECX bytes from ESI to EDI
    pop ecx                    ; Restore counter
    
    ; Copy age (4 bytes)
    mov eax, ecx               ; Current index (source)
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    add eax, AGE_OFFSET        ; Add offset to age
    mov edx, [eax]             ; Get age value from source
    
    mov eax, ecx               ; Current index
    dec eax                    ; Previous index (destination)
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    add eax, AGE_OFFSET        ; Add offset to age
    mov [eax], edx             ; Store age value at destination
    
    jmp .shift_loop            ; Continue shifting
    
.shift_done:
    ; Decrement person counter
    dec dword [nb_personnes]
    
    ; Ne pas afficher la liste mise à jour ici pour éviter le double affichage
    ; call list_persons
    jmp .done
    
.invalid_index:
    ; Invalid index, display error message
    mov esi, msg_err_invalid
    call print_string
    
.done:
    mov esp, ebp
    pop ebp
    ret

; Function: show_extremes
; Shows the oldest and youngest person
show_extremes:
    push ebp
    mov ebp, esp
    sub esp, 16                 ; Allocate local variables (max_age_idx, min_age_idx, max_age, min_age)
    
    ; Check if list is empty
    mov eax, [nb_personnes]
    test eax, eax               ; Check if nb_personnes is zero
    jnz .not_empty
    
    ; List is empty, display message
    mov esi, msg_err_empty
    call print_string
    jmp .done
    
.not_empty:
    ; Initialize variables
    mov dword [ebp-4], -1       ; max_age_idx = -1
    mov dword [ebp-8], -1       ; min_age_idx = -1
    mov dword [ebp-12], 0       ; max_age = 0
    mov dword [ebp-16], 150     ; min_age = 150 (maximum possible age)
    
    ; Setup loop counter (person index)
    mov ecx, 0                  ; ECX will be our loop counter
    
.loop_person:
    ; Calculate address of current person record
    mov eax, ecx                ; Get current index
    imul eax, PERSON_SIZE       ; Multiply by record size
    add eax, personnel          ; Add base address
    
    ; Get age of current person
    add eax, AGE_OFFSET         ; Add offset to age field
    mov edx, [eax]              ; Get age value
    
    ; Check if this is the oldest person so far
    cmp edx, [ebp-12]           ; Compare with current max_age
    jle .check_youngest         ; If not greater, check if youngest
    
    ; Found new oldest
    mov [ebp-12], edx           ; Update max_age
    mov [ebp-4], ecx            ; Update max_age_idx
    
.check_youngest:
    ; Check if this is the youngest person so far
    cmp edx, [ebp-16]           ; Compare with current min_age
    jge .continue_loop          ; If not smaller, continue loop
    
    ; Found new youngest
    mov [ebp-16], edx           ; Update min_age
    mov [ebp-8], ecx            ; Update min_age_idx
    
.continue_loop:
    ; Increment counter and check if we've checked all persons
    inc ecx                     ; Increment index
    cmp ecx, [nb_personnes]     ; Compare with total persons
    jl .loop_person             ; If less, continue loop
    
    ; Check if we have a special case where we have only one person
    mov eax, [nb_personnes]
    cmp eax, 1
    jne .display_results
    
    ; Special case: only one person - display a message indicating this
    mov esi, msg_person_prefix
    call print_string
    
    ; Print message that the same person is both oldest and youngest
    mov esi, msg_single_person
    call print_string
    
    ; Print newline
    mov esi, msg_newline
    call print_string
    
.display_results:
    ; Display the header message
    mov esi, msg_extremes
    call print_string
    
    ; Display oldest person
    mov esi, msg_oldest
    call print_string
    
    ; Calculate address of oldest person record
    mov eax, [ebp-4]           ; Get oldest person index
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    
    ; Print person number (index + 1 for user display)
    mov ebx, [ebp-4]
    inc ebx                    ; 1-based index for display
    
    ; Convert number to string
    mov edi, output_buffer     ; Use output buffer for conversion
    mov byte [edi+10], 0       ; Ensure null-terminated
    mov eax, ebx               ; Put number in EAX for conversion
    mov ebx, 10                ; Divisor for conversion
    add edi, 9                 ; Start at end of buffer
    
.convert_oldest_number:
    xor edx, edx               ; Clear high bits for division
    div ebx                    ; Divide by 10, remainder in EDX
    add dl, '0'                ; Convert to ASCII
    dec edi                    ; Move buffer pointer
    mov [edi], dl              ; Store digit
    test eax, eax              ; Check if quotient is zero
    jnz .convert_oldest_number ; If not, continue conversion
    
    ; Print oldest person index
    mov esi, edi
    call print_string
    
    ; Print space
    mov esi, msg_space
    call print_string
    
    ; Print oldest person name
    mov eax, [ebp-4]           ; Get oldest person index
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    mov esi, eax               ; Point to name
    call print_string
    
    ; Print space
    mov esi, msg_space
    call print_string
    
    ; Print oldest person age
    mov eax, [ebp-4]           ; Get oldest person index
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    add eax, AGE_OFFSET        ; Add offset to age
    mov eax, [eax]             ; Get age value
    
    ; Convert age to string
    mov edi, output_buffer     ; Use output buffer for conversion
    mov byte [edi+10], 0       ; Ensure null-terminated
    mov ebx, 10                ; Divisor for conversion
    add edi, 9                 ; Start at end of buffer
    
.convert_oldest_age:
    xor edx, edx               ; Clear high bits for division
    div ebx                    ; Divide by 10, remainder in EDX
    add dl, '0'                ; Convert to ASCII
    dec edi                    ; Move buffer pointer
    mov [edi], dl              ; Store digit
    test eax, eax              ; Check if quotient is zero
    jnz .convert_oldest_age    ; If not, continue conversion
    
    ; Print oldest person age
    mov esi, edi
    call print_string
    
    ; Print newline
    mov esi, msg_newline
    call print_string
    
    ; Display youngest person (skip if only one person)
    mov eax, [nb_personnes]
    cmp eax, 1
    je .done                   ; Skip if only one person
    
    ; Display youngest person
    mov esi, msg_youngest
    call print_string
    
    ; Calculate address of youngest person record
    mov eax, [ebp-8]           ; Get youngest person index
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    
    ; Print person number (index + 1 for user display)
    mov ebx, [ebp-8]
    inc ebx                    ; 1-based index for display
    
    ; Convert number to string
    mov edi, output_buffer     ; Use output buffer for conversion
    mov byte [edi+10], 0       ; Ensure null-terminated
    mov eax, ebx               ; Put number in EAX for conversion
    mov ebx, 10                ; Divisor for conversion
    add edi, 9                 ; Start at end of buffer
    
.convert_youngest_number:
    xor edx, edx               ; Clear high bits for division
    div ebx                    ; Divide by 10, remainder in EDX
    add dl, '0'                ; Convert to ASCII
    dec edi                    ; Move buffer pointer
    mov [edi], dl              ; Store digit
    test eax, eax              ; Check if quotient is zero
    jnz .convert_youngest_number ; If not, continue conversion
    
    ; Print youngest person index
    mov esi, edi
    call print_string
    
    ; Print space
    mov esi, msg_space
    call print_string
    
    ; Print youngest person name
    mov eax, [ebp-8]           ; Get youngest person index
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    mov esi, eax               ; Point to name
    call print_string
    
    ; Print space
    mov esi, msg_space
    call print_string
    
    ; Print youngest person age
    mov eax, [ebp-8]           ; Get youngest person index
    imul eax, PERSON_SIZE      ; Multiply by record size
    add eax, personnel         ; Add base address
    add eax, AGE_OFFSET        ; Add offset to age
    mov eax, [eax]             ; Get age value
    
    ; Convert age to string
    mov edi, output_buffer     ; Use output buffer for conversion
    mov byte [edi+10], 0       ; Ensure null-terminated
    mov ebx, 10                ; Divisor for conversion
    add edi, 9                 ; Start at end of buffer
    
.convert_youngest_age:
    xor edx, edx               ; Clear high bits for division
    div ebx                    ; Divide by 10, remainder in EDX
    add dl, '0'                ; Convert to ASCII
    dec edi                    ; Move buffer pointer
    mov [edi], dl              ; Store digit
    test eax, eax              ; Check if quotient is zero
    jnz .convert_youngest_age   ; If not, continue conversion
    
    ; Print youngest person age
    mov esi, edi
    call print_string
    
    ; Print newline
    mov esi, msg_newline
    call print_string
    
.done:
    mov esp, ebp
    pop ebp
    ret

; Function: show_average
; Shows the average age of all persons
show_average:
    push ebp
    mov ebp, esp
    sub esp, 16                 ; Allocate local variables (sum, counter, average, etc.)
    
    ; Check if list is empty
    mov eax, [nb_personnes]
    test eax, eax               ; Check if nb_personnes is zero
    jnz .not_empty
    
    ; List is empty, display message
    mov esi, msg_err_empty
    call print_string
    jmp .done
    
.not_empty:
    ; Initialize sum
    mov dword [ebp-4], 0        ; sum = 0
    
    ; Loop through all persons and sum their ages
    mov dword [ebp-8], 0        ; index = 0
    
.sum_loop:
    ; Calculate address of current person record
    mov eax, [ebp-8]            ; Get current index
    imul eax, PERSON_SIZE       ; Multiply by record size
    add eax, personnel          ; Add base address
    add eax, AGE_OFFSET         ; Add offset to age field
    
    ; Add age to sum
    mov edx, [eax]              ; Get age value
    add [ebp-4], edx            ; Add to sum
    
    ; Increment counter and check if we've processed all persons
    inc dword [ebp-8]           ; Increment index
    mov eax, [ebp-8]            ; Load current index
    cmp eax, [nb_personnes]     ; Compare with total persons
    jl .sum_loop                ; If less, continue loop
    
    ; Calculate average
    mov eax, [ebp-4]            ; Load sum
    xor edx, edx                ; Clear EDX for division
    mov ecx, [nb_personnes]     ; Divisor = number of persons
    div ecx                     ; Unsigned division: EDX:EAX / ECX, result in EAX
    
    ; Store average for later use
    mov [ebp-12], eax           ; average = sum / nb_personnes
    
    ; Display average message
    mov esi, msg_average
    call print_string
    
    ; Convert average to string
    mov eax, [ebp-12]           ; Load average
    mov edi, output_buffer      ; Use output buffer for conversion
    mov byte [edi+10], 0        ; Ensure null-terminated
    mov ebx, 10                 ; Divisor for conversion
    add edi, 9                  ; Start at end of buffer
    
.convert_average:
    xor edx, edx                ; Clear high bits for division
    div ebx                     ; Divide eax by 10, remainder in edx
    add dl, '0'                 ; Convert remainder to ASCII
    dec edi                     ; Move buffer pointer
    mov [edi], dl               ; Store digit
    test eax, eax               ; Check if quotient is zero
    jnz .convert_average        ; If not, continue conversion
    
    ; Print average
    mov esi, edi
    call print_string
    
    ; Print space
    mov esi, msg_space
    call print_string
    
    ; Print open parenthesis
    mov esi, msg_open_paren
    call print_string
    
    ; Loop to print all ages
    mov dword [ebp-8], 0        ; Reset index
    
.print_ages_loop:
    ; Calculate address of current person record
    mov eax, [ebp-8]            ; Get current index
    imul eax, PERSON_SIZE       ; Multiply by record size
    add eax, personnel          ; Add base address
    add eax, AGE_OFFSET         ; Add offset to age field
    
    ; Get age
    mov eax, [eax]              ; Load age value
    
    ; Convert age to string
    mov edi, output_buffer      ; Use output buffer for conversion
    mov byte [edi+10], 0        ; Ensure null-terminated
    mov ebx, 10                 ; Divisor for conversion
    add edi, 9                  ; Start at end of buffer
    
.convert_age:
    xor edx, edx                ; Clear high bits for division
    div ebx                     ; Divide eax by 10, remainder in edx
    add dl, '0'                 ; Convert remainder to ASCII
    dec edi                     ; Move buffer pointer
    mov [edi], dl               ; Store digit
    test eax, eax               ; Check if quotient is zero
    jnz .convert_age            ; If not, continue conversion
    
    ; Print age
    mov esi, edi
    call print_string
    
    ; Check if we need to print a space (not after the last age)
    mov eax, [ebp-8]
    inc eax
    cmp eax, [nb_personnes]
    jge .skip_space
    
    ; Print space
    mov esi, msg_space
    call print_string
    
.skip_space:
    ; Increment and check if we've printed all ages
    inc dword [ebp-8]           ; Increment index
    mov eax, [ebp-8]            ; Load current index
    cmp eax, [nb_personnes]     ; Compare with total persons
    jl .print_ages_loop         ; If less, continue loop
    
    ; Print close parenthesis
    mov esi, msg_close_paren
    call print_string
    
    ; Print newline
    mov esi, msg_newline
    call print_string
    
.done:
    mov esp, ebp
    pop ebp
    ret
