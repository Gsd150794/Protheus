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
Programa----------: MTA650L 
Autor-------------: Alex Wallauer
Data da Criacao---: 18/01/2023
Descrição---------: P.E. Troca de linha e OK final NA TELA DE AJUSTE DE EMPEMHOS
------------------  Chamado 42590: Novo validacao para não deixar os aramzens sem preencher
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar 
------------------: .F. = Nao Permite confirmar 
===============================================================================================================================
*/
User Function MTA650L()
Local nI, bBloco
Local _cItens:=""
Local _cSpcC :=13
Local _cSpcT :=15

If IsInCallStack("A650AETdOk")
    
    _cItens:=""
	_cSpcC:=13
	_cSpcT:=15
	For nI := 1 To Len(aCols)
    	If !aCols[nI,Len(aCols[nI])]  .And. Empty(aCols[nI,nPosLocal])
   		   _cItens += AllTrim(aCols[nI,nPosCod])+Space(_cSpcT)+aCols[nI,nPosLocal]+CRLF
    	EndIf
    Next 

    If !Empty(_cItens)
       bBloco:={|| AVISO("ATENCAO","  PRODUTO"+Space(_cSpcC)+"ARMAZEM"+CRLF+_cItens,{"Fechar"},3) }
       U_ITMsg("Existem Produtos com o armazem não preenchido","ATENCAO","Clique em mais detalhes para ver os produtos",1,,,,,,bBloco)
	   Return .F.
	EndIf
Else
  	If !aCols[N,Len(aCols[N])]  .And. Empty(aCols[N,nPosLocal])
       U_ITMsg("Produto "+aCols[N,nPosCod]+" com o armazem não preenchido","ATENCAO","Preencha o armazem",1)
	   Return .F.
    EndIf
EndIf

Return .T.
