      *> MAIN
       identification division.
       program-id. Program1.

       environment division.
       configuration section.
       input-output section.
       file-control.
           select archivo-empleados
               assign to "data/empleados.dat"
               organization is line sequential
               access mode is sequential
               file status is ws-estado-archivo.

       data division.
       file section.
       fd archivo-empleados.
       01 registro-empleado.
           05 emp-id          pic 9(3).
           05 emp-nombre      pic x(20).
           05 emp-salario     pic 9(6).

       working-storage section.
       01 ws-estado-archivo   pic xx value spaces.
       01 ws-contador         pic 999999999999 value 0.
       01 ws-total-salarios   pic 999999999999 value 0.
       01 ws-fin-archivo      pic x value 'N'.

       procedure division.
       inicio.
           open input archivo-empleados
           if ws-estado-archivo not = '00'
               display "Error al abrir el archivo: " ws-estado-archivo
               stop run
           end-if

           display "======================================"
           display " ID  Nombre               Salario"
           display "======================================"

           perform until ws-fin-archivo = 'S'
               read archivo-empleados
                   at end
                       move 'S' to ws-fin-archivo
                   not at end
                       add 1 to ws-contador
                       add emp-salario to ws-total-salarios
      *                 display emp-id " "
      *                         emp-nombre " "
      *                         emp-salario
               end-read
           end-perform

           display "======================================"
           display "Registros procesados: " ws-contador
           display "Total salarios:       " ws-total-salarios
           display "======================================"

           close archivo-empleados
           goback.

       end program Program1.