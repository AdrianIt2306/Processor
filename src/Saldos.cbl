       identification division.
       program-id. saldos.

       data division.
       working-storage section.

           exec sql include sqlca end-exec.

           exec sql begin declare section end-exec.
       01 hv-customers      pic s9(9) comp-5 value 0.
           exec sql end declare section end-exec.

       procedure division.
       inicio.
           exec sql
               connect to default
           end-exec

           if sqlcode not = 0
               display "Error CONNECT SQLCODE=" sqlcode
               display "SQLSTATE=" sqlstate
               goback
           end-if

           exec sql
               select count(*)
                 into :hv-customers
                 from customers
           end-exec

           if sqlcode not = 0
               display "Error SELECT SQLCODE=" sqlcode
               display "SQLSTATE=" sqlstate
           else
               display "CUSTOMERS total: " hv-customers
           end-if

           exec sql disconnect end-exec

           goback.

       end program saldos.