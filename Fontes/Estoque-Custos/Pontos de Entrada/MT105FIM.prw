/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |30/12/2021| Chamado 38778. Nova validacao para deletar o SCR: LEFT(ZZL->ZZL_MATRIC,2) <> SCR->CR_FILIAL
Alex Wallauer |07/01/2022| Chamado 38855. Mais uma validacao para deletar o SCR: !SCR->CR_FILIAL $ ZZL->ZZL_FILAPSA
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT105FIM
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Este Ponto de Entrada e no final da inclusao ou alteracao de dados no arquivo SCP. Chamado 33355
Parametros--------: ParamIXB => nOpcao (Numerico)
                    [1] Inclusado
                    [2] Alteracao
                    [3] Exclusao
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT105FIM()
Local _aArea:= FWGetArea()
Local nOpcao:= ParamIXB
Local _cNum	:= SCP->CP_NUM
Local _cGrup:= SCP->CP_I_GRAPR
Local nLenSC:= Len(SCP->CP_NUM)//-- Controle de tamanho de campo do documento

If nOpcao = 3 .Or. ISINCALLSTACK("MDTA695") //Exclusao 
   Return .T.
EndIf		

DBSelectArea("SCR")
DBCOMMIT()
DBCOMMITALL()

SCR->(DBSetOrder(1))
SCR->(DBSeek(xFilial("SCR")+"SA"+ _cNum))

While (!SCR->(Eof()) .And. ( SCR->CR_FILIAL+SCR->CR_TIPO+LEFT(SCR->CR_NUM,nLenSC)  == xFilial("SCR")+"SA"+ _cNum ) )

   _cGRPAPR := Posicione("ZZL",3,xFilial("ZZL")+SCR->CR_USER,"ZZL_GRPAPR")

   If (_cGrup <> _cGRPAPR .And. _cGRPAPR <> "0") .Or. If( ZZL->(FIELDPOS("ZZL_FLAPSA")) <> 0 .And. !Empty(ZZL->ZZL_FLAPSA),!SCR->CR_FILIAL $ ZZL->ZZL_FLAPSA,FWSFAllUsers({ZZL->ZZL_CODUSU},{"USR_FILIAL"})[1][3] <> SCR->CR_FILIAL)
	   SCR->(RecLock("SCR",.F.))
	   SCR->(DBDELETE())
	   SCR->(MSUnLock())
   EndIf
   SCR->(DBSkip())

EndDo
FWRestArea(_aArea)		
Return .T.
