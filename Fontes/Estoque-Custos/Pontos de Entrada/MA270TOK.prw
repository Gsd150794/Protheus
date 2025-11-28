/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |16/04/2019| Chamado 28685. Validação p/ não permitir fracionamento de UM que são inteiras.
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA270TOK
Autor-------------: Renato de Morcerf
Data da Criacao---: 03/02/2009
Descrição---------: Ponto de Entrada que valida movimento lancamento de inventario
Parametros--------:
Retorno-----------: .T. = Permite confirmar lancamento
------------------: .F. = Nao Permite confirmar lancamento
===============================================================================================================================
*/
User Function MA270TOK()

Local	aArea	:= FWGetArea()
Local 	_npl  	:= M->B7_COD
Local 	nQtd2UM := M->B7_QTSEGUM
Local	nQtd    := M->B7_QUANT
Local 	n_ret	:= .T.   
Local _cUM_NO_Fracionada:=SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN")
Local _lValidFrac1UM:=.T.

If SubStr(_npl,1,4) == "0006"
	If nQtd2UM == 0 .And. nQtd > 0 
		xMagHelpFis("Segunda Unidade de Medida Vazio","Para esse produto e obrigatorio o preenchimento da segunda unidade de medida (Peças).",;
		"Favor preencher a segunda unidade de medida (Peças)!!")
		n_ret := .F.
	EndIf
EndIf

If Altera .And. M->B7_I_ACERT = "1" .And. !Empty(M->B7_I_DTACE)
	xMagHelpFis("Inventário já processado","Alteração não permitida para inventários já processados",;
		"Favor incluir novo lançamento de inventário")
	n_ret := .F.
EndIf

ZZL->( DBSetOrder(3) )
If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
   If ZZL->(FIELDPOS("ZZL_PEFRPA")) = 0 .Or. ZZL->ZZL_PEFRPA == "S"
	  _lValidFrac1UM:=.F.
   EndIf
EndIf
ZZL->( DBSetOrder(1) )

SB1->(DBSetOrder(1))
If n_ret .And._lValidFrac1UM .And. SB1->(DBSeek(xFilial("SB1") + M->B7_COD )) //.AND. SB1->B1_TIPO == "PA" 
   If (SB1->B1_UM $ _cUM_NO_Fracionada .And. M->B7_QUANT <> Int(M->B7_QUANT))
		U_ITMsg("Não é permitido fracionar a quantidade da 1a. UM de produto onde a Unid. Medida For "+_cUM_NO_Fracionada+".",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
		        "Validação Fracionado",;
		        "Favor informar apenas quantidades inteiras na Primeira Unidade de Medida.",1)

		n_ret := .F. 
   EndIf
   If ( SB1->B1_SEGUM $ _cUM_NO_Fracionada .And. M->B7_QTSEGUM <> Int(M->B7_QTSEGUM) )
		U_ITMsg("Não é permitido fracionar a quantidade da 2a. UM de produto onde a Unid. Medida For "+_cUM_NO_Fracionada+".",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
		        "Validação Fracionado",;
		        "Favor informar apenas quantidades inteiras na Segunda Unidade de Medida.",1)

		n_ret := .F. 
	EndIf
EndIf

FWRestArea(aArea)

Return n_ret
