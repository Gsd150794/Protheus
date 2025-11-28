/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: F420CRP
Autor-----------: Alex Wallauer
Data da Criacao-: 06/06/2022 
Descrição-------: Ponto de entrada no final do progrma FINA420.PRX - Geracao do Arquivo SisPag, Chamado 40354
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function F420CRP()
    
If (GetRemoteType() == 5) //Valida se o ambiente é SmartClientHtml

   If File(AllTrim(MV_PAR04))
      //U_ITMsg("Gerou o aquivo: "+AllTrim(MV_PAR04),'Atenção!',,2) // OK
      If CpyS2TW(AllTrim(MV_PAR04),.T. ) = 0 //Indica se, falso (.F.), o arquivo será apenas copiado ou se, verdadeiro (.T.), será copiado e enviado para o browser
         // U_ITMsg("Conseguiu Copiar o aquivo: "+AllTrim(MV_PAR04),'Atenção!',,2) // OK
      Else
          U_ITMsg("Não conseguiu Copiar o aquivo: "+AllTrim(MV_PAR04),'Atenção!',,3) // OK 
      EndIf
   
   Else
      U_ITMsg("Não gerou "+AllTrim(MV_PAR04),'Atenção!',,3) // OK
   EndIf

EndIf

Return .T.
