/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Chamado 28346 - Removidos os Warning na compilação da release 12.1.25. 
-------------------------------------------------------------------------------------------------------------------------------
 Igor Melgaço     | 21/03/2023 | Chamado 41686 - Ajuste para alimentação do Codigo FCI.
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MSD2460
Autor-------------: Wodson Reis Silva
Data da Criacao---: 06/02/2009
===============================================================================================================================
Descrição---------: Usado para gravar os campos de usuario do Pedido de Venda no item da Nota.
					Grava a quantidade de caixas dos itens do grupo queijo, vendidos no Pedido.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MSD2460()

Local _cAlias  := Alias()
Local _aAmb    := FWGetArea()

//Salvando Integridade do Sistema.
DBSelectArea("SF2")
_nOrdSF2 := IndexOrd()
_nRecSF2 := Recno()

DBSelectArea("SD2")
_nOrdSD2 := IndexOrd()
_nRecSD2 := Recno()

DBSelectArea("SB1")
_nOrdSB1 := IndexOrd()
_nRecSB1 := Recno()

DBSelectArea("SF4")
_nOrdSF4 := IndexOrd()
_nRecSF4 := Recno()

DBSelectArea("SC5")
_nOrdSC5 := IndexOrd()
_nRecSC5 := Recno()

DBSelectArea("SC6")
_nOrdSC6 := IndexOrd()
_nRecSC6 := Recno()                    

DBSelectArea("SBZ")
_nOrdSBZ := IndexOrd()
_nRecSBZ := Recno()                    

//Gravacao de campo de usuario do SC6 no SD2
DBSelectArea("SC6")
DBSetOrder(1)//C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
If DBSeek(xFilial("SC6")+SD2->D2_PEDIDO+SD2->D2_ITEMPV+SD2->D2_COD)
	RecLock("SD2",.F.)
	SD2->D2_I_DQESP := SC6->C6_I_DQESP
	SD2->(MSUnLock())
EndIf

DBSelectArea("SBZ")
SBZ->( DBSetOrder(1) )    //BZ_FILIAL+BZ_COD
If SBZ->( DBSeek(xFilial("SBZ") + SD2->D2_COD) )
	If !Empty(AllTrim(SBZ->BZ_I_FCICO ))
		RecLock("SD2",.F.)
		SD2->D2_FCICOD := SBZ->BZ_I_FCICO 
		SD2->(MSUnLock())
	EndIf
EndIf
                           
DBSelectArea("SD2")
DBSetOrder(_nOrdSD2)
DBGoTo(_nRecSD2)

DBSelectArea("SF2")
DBSetOrder(_nOrdSF2)
DBGoTo(_nRecSF2)

DBSelectArea("SB1")
DBSetOrder(_nOrdSB1)
DBGoTo(_nRecSB1)

DBSelectArea("SF4")
DBSetOrder(_nOrdSF4)
DBGoTo(_nRecSF4)

DBSelectArea("SC5")
DBSetOrder(_nOrdSC5)
DBGoTo(_nRecSC5)

DBSelectArea("SC6")
DBSetOrder(_nOrdSC6)
DBGoTo(_nRecSC6)

DBSelectArea("SBZ")
DBSetOrder(_nOrdSBZ)
DBGoTo(_nRecSBZ)

DBSelectArea(_cAlias)
FWRestArea(_aAmb)

Return
