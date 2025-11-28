/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |12/04/2019| Chamado 28685. Validação p/ não permitir fracionamento de UM que são inteiras
===============================================================================================================================
*/

#Include "TOTVS.ch"   

/*
===============================================================================================================================
Programa----------: MA650TOK
Autor-------------: Carlos Cleber A.Silva
Data da Criacao---: 08/01/2014 
Descricao---------: Geração de Ordens de Produção chamado da função A650TudoOk() do MATA650
Parametros--------: Nenhum
Retorno-----------: lRet := .T. Prossegue com a criacao da OP 
                    lRet := .F. Nao prossegue com a criacao da OP
===============================================================================================================================
*/
User Function MA650TOK()    

Local lRet     := .T.  
Local dDtServ  := dDataBase
Local dDtAtual := Date() 
Local dDtEms   := (M->C2_EMISSAO)
Local _lValidFrac1UM:=.T.

If dDtServ > dDtAtual .Or. dDtEms > dDtServ  
   U_ITMsg("Para incluir Ordem de Produção a 'Data de emissão' não pode ser maior que a 'Data atual do servidor ou Data base do sistema'. Não é permitido criar Ordem de Produção com data futura! ",;
	       "PROBLEMA DATA BASE","Data Atual(SO): "+DToC(dDtAtual)+" "+CRLF+"Data Base(Sistema): "+DToC(dDtServ)+" "+CRLF+"Data Emissão: "+DToC(dDtEms),; 
		   "Conferir a 'Data Base do sistema' e ajustar a 'Data de emissão' se necessário.",1)
   lRet := .F. 
EndIf

ZZL->( DBSetOrder(3) )
If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
   If ZZL->(FIELDPOS("ZZL_PEFRPA")) = 0 .Or. ZZL->ZZL_PEFRPA == "S"
	  _lValidFrac1UM:=.F.
   EndIf
EndIf
ZZL->( DBSetOrder(1) )

SB1->(DBSetOrder(1))
If _lValidFrac1UM .And. SB1->(DBSeek(xFilial("SB1") + M->C2_PRODUTO )) .And. SB1->B1_TIPO == "PA" 
   If (SB1->B1_UM == "UN" .And. M->C2_QUANT <> Int(M->C2_QUANT))
		U_ITMsg("Não é permitido fracionar a quantidade da 1a. UM de produto onde a Unid. Medida For UN.",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
		        "Validação Fracionado",;
		        "Favor informar apenas quantidades inteiras na Primeira Unidade de Medida.",1)

		lRet := .F. 
   EndIf
   If ( SB1->B1_SEGUM = "PC" .And. LEFT(M->C2_PRODUTO,4)=="0006" .And. M->C2_QTSEGUM <> Int(M->C2_QTSEGUM) )
		U_ITMsg("Não é permitido fracionar a quantidade da 2a. UM de produto do grupo 0006 onde a Unid. Medida For PC.",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
		        "Validação Fracionado",;
		        "Favor informar apenas quantidades inteiras na Segunda Unidade de Medida.",1)

		lRet := .F. 
	EndIf
EndIf

Return(lRet)
