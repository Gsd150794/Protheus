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
Programa----------: MTA175MNU
Autor-------------: Alex Wallauer
Data da Criacao---: 17/07/2019  
Descrição---------: Ponto de entrada para criar um botao na tela liberacoes/rejeicoes do CQ. CHAMADO 30023
Parametros--------: Nenhum
ARetorno-----------: aBotao
===============================================================================================================================
*/
User Function MTA175MNU()

aAdd(aRotina , {"Motivo do Retrabalho", 'U_MA175MR'	, 0, 2, 0, .F.}  )

Return aRotina

/*
===============================================================================================================================
Programa----------: MA175BUT
Autor-------------: Alex Wallauer
Data da Criacao---: 17/07/2019  
Descrição---------: SELECAO Motivo do Retrabalho
Parametros--------: Nenhum
ARetorno-----------: aBotao
===============================================================================================================================
*/
User Function MA175MR()

Local lREt:=.F.

If !Empty(SD7->D7_LIBERA) .And. !U_ITMsg("O Produto já foi Liberado pelo C.Q. deseja alterar o campo Motivo mesmo assim?",'Atenção!',,3,2,2)
   Return .F.
EndIf   

If SD7->D7_TIPO = 2
   U_ITMsg("Linha Rejeitada. Campo motivo não pode ser aterado.",'Atenção!',,1)
   Return .F.
EndIf   

DBSelectArea('CYO')
lREt := ConPad1(,,,'CYO003',,,.F.)

If lREt
   SD7->(RecLock('SD7', .F.))
   SD7->D7_MOTREJE:=CYO->CYO_CDRF
   SD7->(MSUnLock())
ElseIf !Empty(SD7->D7_MOTREJE) .And. U_ITMsg("Deseja Limpar o campo Motivo ?",'Atenção!',,3,2,2)
   SD7->(RecLock('SD7', .F.))
   SD7->D7_MOTREJE:=""
   SD7->(MSUnLock())
EndIf

Return 
