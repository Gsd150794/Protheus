/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |12/12/2023| Chamado 45848. Possibilitar a baixa com juros ou não pela rotina
Alex Wallauer |15/12/2023| Chamado 45848. Alterado para usar a função de mensagem padrão: U_ITMsg()
===============================================================================================================================
*/

#Include "Totvs.ch"

/*
===============================================================================================================================
Programa----------: FA110JUR
Autor-------------: Antonio Ramos
Data da Criacao---: 12/12/2023
Descrição---------: Rotina de Baixa Automática de Títulos possibilitando a escolha de considerar juros ou não. FINA110
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function FA110JUR ()

If U_ITMsg("Desconsidera Juros ?"+Chr(13)+Chr(10)+"Título: "+SE1->E1_NUM+" - Parc.: "+SE1->E1_PARCELA;
                +" - Saldo:"+Transform(SE1->E1_SALDO, "@E 999,999,999,999.99");
                +" - Juros:"+Transform(nJuros, "@E 999,999,999,999.99"),"Cliente: "+AllTrim(SE1->E1_NOMCLI),,2,2,2,)// OK    SIM E NÃO
    nJuros := 0
EndIf 

Return nJuros
