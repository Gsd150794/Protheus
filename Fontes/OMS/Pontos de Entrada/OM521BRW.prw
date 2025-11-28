/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Fricks   |01/02/2024| Chamado 46197. Tratativas para cancelamento do faturamento de uma carga no TMS Multiembarcador.
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
==================================================================================================================================================================================================================
Analista        - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==================================================================================================================================================================================================================
Jerry Santiago  - Alex Wallauer - 27/06/25 - 27/06/25 -  51066 - Ajustes do cancelamento de carga para deletar o DAK e o DAI senão tiver mais SC9 para o pedido do DAI.
Jerry Santiago  - Alex Wallauer - 02/03/25 - 03/07/25 -  51221 - Ajustes do cancelamento de carga para deletar o Pallet senão tiver mais SC9 para o pedido do DAI.
Jerry Santiago  - Alex Wallauer - 07/07/25 - 07/07/25 -  51280 - Ajustes do cancelamento de carga para deletar os Trocas NF senão tiver mais SC9 para o pedido do DAI.
==================================================================================================================================================================================================================
*/

#Include "TOTVS.ch"
#Define DS_MODALFRAME	128
/*
=================================================================================================================================
Programa----------: OM521BRW
Autor-------------: Alex Wallauer
Data da Criacao---: 25/10/2019
Descrição---------: PE antes dos mBrowse's do estorno dos documentos de entrada no programa MATA521.PRX/MATA521B - Antigo M520BROW
Parametros--------: Nenhum
Observação--------: Esse PE é chamado em 3 lugares no programa MATA521.PRX sempre antes dos mBrowse's
==================================================================================================================================
*/
User Function OM521BRW()

Local aRotina := ParamIXB
Local _nPos:=aScan(aRotina, {|R| Upper(R[2]) == Upper("OM521Exclu") } )

If _nPos # 0
	aRotina[_nPos,2] := "U_ITMa521Mbrow"
	aAdd(aRotina, {"Corrgir Exclusao","U_ITMa521Corri",0,5} )
EndIf

Return aRotina
/*
===============================================================================================================================
Programa--------: ITMa521Corri()
Autor-----------: Alex Wallauer
Data da Criacao-: 03/10/2016
Descrição-------: Tela da Correçao da exclusão da carga 
Parametros------: cAlias: Alias da Carga
Retorno---------: Lógico (.T.) 
===============================================================================================================================
*/
User Function ITMa521Corri(cAlias)

Local nLinha:=10
Local nCol1 :=30
Local nCol2 :=nCol1+50
Local oDlg
Local lOK:=.F.
Local _cCarga:=Space(Len(DAK->DAK_COD))

While .T.
	// Inicializa as variáveis MV_PARxx do Pergunte("MTA521",.F.)
	// Chamado ao Teclar F12.
	// Com a ultima opção selecionada.
	Pergunte("MTA521",.F.)

	lOK:=.F.
	nLinha:=10
	DEFINE MSDIALOG oDlg TITLE "Corrige a exclusão da carga (OM521BRW)" FROM 000,000 TO 100,350 PIXEL

	@ nLinha+2,nCol1 Say "Numero da Carga:" OF oDlg Pixel
	@ nLinha,nCol2 MSGET _cCarga  OF oDlg PIXEL SIZE 46, 09  F3 "DAK"
	nLinha+=20
	TButton():New( nLinha , nCol1-15 , ' Confirma '	,  , {|| If(!Empty(_cCarga),(lOK:=.T.,oDlg:END()), MSGSTOP("Preencha a Carga!") ) }	, 60 , 15 ,,,, .T. )
	TButton():New( nLinha , nCol1+60 , ' Cancela '	,  , {|| lOK:=.F.,oDlg:END() }	, 60 , 15 ,,,, .T. )

	ACTIVATE MSDIALOG oDlg Centered

	If lOK
		M520_Valida(xFilial("DAK"),_cCarga,"01",.T.)
		Loop
	EndIf

	Exit
EndDo

Return .T.

/*
===============================================================================================================================
Programa--------: ITMa521Mbrow()
Autor-----------: Alex Wallauer
Data da Criacao-: 03/10/2016
Descrição-------: Exclusão de Notas de Entrada da Carga , Padrão , Custumizada e do TMS
Parametros------: cAlias: Alias da Carga
Retorno---------: Lógico (.T.) 
===============================================================================================================================
*/
User Function ITMa521Mbrow(cAlias)

Local cAliasSF2
Local cQuery
Local _aArea     := FWGetArea()
Local _aAreaDAK  := DAK->(FWGetArea())
Local _aAreaDAI  := DAI->(FWGetArea())
Local _aAreaSF2  := SF2->(FWGetArea())
Local _aAreaSC5  := SC5->(FWGetArea())
Local _cFilCarga := DAK->DAK_FILIAL
Local _cCarga    := DAK->DAK_COD
Local _cSeqCarga := DAK->DAK_SEQCAR

Private _lDeuErro  :=.F.
Private _nRecno_DAK := DAK->(RECNO())
Private _lNotaCarga := .T.

If cAlias # "DAK"
	_lNotaCarga := .F.
	//FUNCAO PADRAO CHAMADA DO aRotina// AQUI DENTRO ELE CHAMDA OUTROS Pontos de Entrada
	OM521Exclu(cAlias)//Ma521Mbrow(cAlias)//Se NÃO For o alias da carga "DAK" roda o padrao normal
	//FUNCAO PADRAO CHAMADA DO aRotina// AQUI DENTRO ELE CHAMDA OUTROS Pontos de Entrada
	Return .T.
EndIf

If DAK->DAK_ACEFIN <> "2"
	Help(" ",1,"OMS320JAFIN") //"Acerto financeiro ja efetuado"
	Return .F.
ElseIf DAK->DAK_ACECAR<>"2"
	Help(" ",1,"OMS320JAAC") //Carga ja encerrada
	Return .F.
EndIf

DBSelectArea("SF2")
DBSetOrder(1)

cAliasSF2 := GetNextAlias()
cQuery := "SELECT R_E_C_N_O_ SF2RECNO "
cQuery += "FROM "+RetSqlName("SF2")+" SF2 "
cQuery += "WHERE "
cQuery += "SF2.F2_FILIAL='"+_cFilCarga+"' AND "
cQuery += "SF2.F2_CARGA='"+_cCarga+"' AND "
cQuery += "SF2.F2_SEQCAR='"+_cSeqCarga+"' AND "
cQuery += "SF2.D_E_L_E_T_=' ' "

MPSysOpenQuery( cQuery , cAliasSF2)
DBSelectArea(cAliasSF2)

(cAliasSF2)->(DBGoTop())

If (cAliasSF2)->(Eof()) .And. (cAliasSF2)->(Bof())
	_cProblema:="Não existem notas para essa Carga."
	_cSolucao :="Selecione uma carga que possua Notas geradas."
	xMagHelpFis("Atenção (OM521BRW) 001",_cProblema,_cSolucao)
	_lDeuErro:=.T.
EndIf

While (cAliasSF2)->(!Eof())
	SF2->(MsGoto((cAliasSF2)->SF2RECNO))
	If !U_MS520VLD(.F.)//Ponto de Entrada no momento da exclusao da Nota Fiscal de Saida (SF2), Esse ponto é executado para cada linha do SF2
		_lDeuErro:=.T.
	EndIf
	(cAliasSF2)->(DBSkip())
EndDo

If !_lDeuErro .And. DAK->DAK_I_TMS = 'M'
	FWMsgRun(, { |oproc| _lDeuErro := !(U_OM521TMS(oproc,cAliasSF2,.F.))}, 'Aguarde...','Iniciando exclusão de nota de entrada...')

	If !totvs.framework.environment.Type.get() == '1' .And. _lDeuErro //1-Produção, 2-Homologação,3-Desenvolvimento
		_lDeuErro  := !(MSGYESNO( "Mesmo após a falha de integração com o TMS, deseja continuar a exclusão? ", "Atenção!" ))
	EndIf
EndIf

(cAliasSF2)->(DBCloseArea())

FwRestArea(_aArea)
FwRestArea(_aAreaDAK)
FwRestArea(_aAreaDAI)
FwRestArea(_aAreaSF2)
FwRestArea(_aAreaSC5)

If _lDeuErro
	Return .F.
EndIf
_lUsuConfirmou:=.F.//é colocado .T. nessa variavel no rdmake MS520VLD.PRW

//FUNCAO PADRAO CHAMADA DO aRotina// AQUI DENTRO ELE CHAMDA OUTROS Pontos de Entrada
LjMsgRun( "Executando Exclusão Padrão..." , "Aguarde..." , {|| OM521Exclu(cAlias) } )
//FUNCAO PADRAO CHAMADA DO aRotina// AQUI DENTRO ELE CHAMDA OUTROS Pontos de Entrada

If !_lUsuConfirmou
	Return .F.
EndIf

M520_Valida(_cFilCarga,_cCarga,_cSeqCarga,.F.)

FWRestArea(_aArea)

Return .T.

/*
===============================================================================================================================
Programa--------: M520_Valida()
Autor-----------: Alex Wallauer
Data da Criacao-: 03/10/2016
Descrição-------: Valida Carga para estornar
Parametros------: _cFilCarga: Filial ,_cCarga: Carga Posicionada ,_cSeqCarga: Seq da Carga,
                  lCarga_Digitada: Se a carga foi digitada pelo usuario
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================
*/
Static Function M520_Valida(_cFilCarga,_cCarga,_cSeqCarga,lCarga_Digitada)

Local _cNotas  := "",_lRet:=.T.
Local _aArea   := FWGetArea()
Local cAliasSF2:= GetNextAlias()
Local cQuery:= "SELECT R_E_C_N_O_ SF2RECNO FROM "+RetSqlName("SF2")+" SF2 WHERE "

cQuery += "SF2.F2_FILIAL = '"+_cFilCarga+"' AND "
cQuery += "SF2.F2_CARGA = '"+_cCarga+"' AND "
cQuery += "SF2.F2_SEQCAR = '"+_cSeqCarga+"' AND "
cQuery += "SF2.D_E_L_E_T_ = ' ' "

MPSysOpenQuery( cQuery , cAliasSF2)
DBSelectArea(cAliasSF2)

While (cAliasSF2)->(!Eof())
	SF2->(MsGoto((cAliasSF2)->SF2RECNO))
	_cNotas+=SF2->F2_DOC+"/"+SF2->F2_SERIE+", "
	(cAliasSF2)->(DBSkip())
EndDo

(cAliasSF2)->(DBCloseArea())

FWRestArea(_aArea)

If !Empty(_cNotas)
	_cNotas   :=LEFT(_cNotas,Len(_cNotas)-2)
	_cProblema:="Ainda existe(m) nota(s) para essa Carga."
	_cSolucao :="Verifique as Notas abaixo no Monitor do NFe-Sefaz. "+  CRLF + _cNotas
	// _cSolucao :="Verifique as notas e tente excluir novamente a Carga. Nota(s): "+_cNotas
	xMagHelpFis("Atenção (OM521BRW) 002",_cProblema,_cSolucao)
	FWRestArea(_aArea)
	Return .F.
Else
	LjMsgRun( "Executando Exclusão Customizada..." , "Aguarde..." , {|| _lRet := M520_Volta_Pedidos(_cFilCarga,_cCarga,_cSeqCarga,lCarga_Digitada) } )
EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa--------: M520_Volta_Pedidos()
Autor-----------: Alex Wallauer
Data da Criacao-: 29/09/2016
Descrição-------: Estono da Unificação de pedidos de troca nota
Parametros------: _cFilCarga: Filial ,
                  _cCargaExclui: Carga a ser excluida ,
                  _cSeqCarga: Seq da Carga ,
                  lCarga_Digitada: Se a carga foi digitada pelo usuario
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================
*/
Static Function M520_Volta_Pedidos(_cFilCarga,_cCargaExclui,_cSeqCarga,lCarga_Digitada)

Local _cAlias:= GetNextAlias()
Local _cQuery , nInc , P
Local _cFilCarregamento:=""
Local _cPedCarregamento:=""
Local _cFilCarreg := ""

Private _lAchouCarga:=.F.
Private _lAchouSC9  :=.F.

DAI->( DBSetOrder(1) )
DAK->( DBSetOrder(1) ) //DAK_FILIAL+DAK_COD+DAK_SEQCAR

_cQuery := " SELECT  DAI.DAI_FILIAL, DAI.DAI_COD, DAI.DAI_PEDIDO, DAK.R_E_C_N_O_ REC_DAK, DAI.R_E_C_N_O_ REC_DAI "
_cQuery += " FROM  "+ RetSqlName('DAI') +" DAI , "+ RetSqlName('DAK') +" DAK "
_cQuery += " WHERE DAK.DAK_FILIAL = '"+_cFilCarga+"'"
_cQuery += " AND DAK.DAK_COD = '"+_cCargaExclui+"'"
_cQuery += " AND DAK.DAK_SEQCAR = '"+_cSeqCarga+"'"

If DAK->( DBSeek( _cFilCarga+_cCargaExclui+_cSeqCarga ) ) .AND.;
		DAI->( DBSeek( _cFilCarga+_cCargaExclui+_cSeqCarga ) )//Tem casos que os estorno deleta a carga e tem casos que nao, depende do parametro do pergunto do F12
	_lAchouCarga:=.T.
	_cQuery += " AND "+ RetSqlDel('DAI')+" AND "+ RetSqlDel('DAK')//Se achou tira os Deletados senao procura a carga nos deletados
EndIf

_cQuery += " AND DAI_FILIAL = DAK.DAK_FILIAL  "
_cQuery += " AND DAI.DAI_COD = DAK.DAK_COD "
_cQuery += " AND DAI.DAI_SEQCAR = DAK.DAK_SEQCAR "
_cQuery += " ORDER BY DAI.DAI_FILIAL, DAI.DAI_COD, DAI.DAI_PEDIDO "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

MPSysOpenQuery( _cQuery , _cAlias)
DBSelectArea(_cAlias)

(_cAlias)->( DBGoTop() )

If (_cAlias)->(Eof()) .And. (_cAlias)->(Bof())
	_cProblema:="Numero da Carga nunca existiu."
	_cSolucao :="Digite um numero de carga cadastrado ou que já existui no sistema."
	xMagHelpFis("Atenção (OM521BRW) 003",_cProblema,_cSolucao)
	Return .F.
EndIf

//ESSE TRECHO TB ESTA NO RDMAKE M521DNFS.PRW PARA NÃO EXECUTAR 2 VESES DO ESTONO DA NOTA POR CARGA
_cIT_MPVOP:=AllTrim(SuperGetMV('IT_MPVOP',.T.,'50/51/02'))
aheader:={}
aAdd(aheader,{1,"C6_ITEM"})
aAdd(aheader,{2,"C6_PRODUTO"})
aAdd(aheader,{3,"C6_LOCAL"})
SC6->(DBSetOrder(1))
SC9->( DBSetOrder(1) )//C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
	DAI->( DBGoTo( (_cAlias)->REC_DAI) )
	If !SC5->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_PEDIDO ) )
		(_cAlias)->( DBSkip() )
		Loop
	EndIf

	If SC9->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_PEDIDO ) )
		_lAchouSC9 := .T.
	EndIf

	U_ENVSITPV() //Envia situação do pedido de venda para o RDC

	If !AllTrim(SC5->C5_I_OPER) $ _cIT_MPVOP
		SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
		aCols:={}
		While SC6->(!Eof()) .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->C5_NUM == SC6->C6_NUM
			aAdd(aCols,{SC6->C6_ITEM,SC6->C6_PRODUTO,SC6->C6_LOCAL})
			SC6->(DBSkip())
		EndDo

		_cFilCarreg := SC5->C5_FILIAL
		If ! Empty(SC5->C5_I_FLFNC)
			_cFilCarreg := SC5->C5_I_FLFNC
		EndIf

		_dGetNE := SC5->C5_I_DTENT - (U_OMSVLDENT(SC5->C5_I_DTENT,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FILFT,SC5->C5_NUM,1, ,_cFilCarreg,SC5->C5_I_OPER,SC5->C5_I_TPVEN))
		_cCOMENT:= "*********** ESTORNO DE FATURAMENTO *************************"

		U_GrvMonitor(,,"014",_cCOMENT,"I",_dGetNE,SC5->C5_I_DTENT,SC5->C5_I_DTENT)//Monitor pedido de vendas
	EndIf

	(_cAlias)->( DBSkip() )
EndDo

_aPeds_Fat   :={}
_aNF_Fat     :={}
_aPeds_Prod  :={}
_aPeds_Triag :={}
_aCargaAcerta:={}
_cCargaCarregamento:=""
_cPVFats:=""
_cNFEs:=""
_cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.T.,"05,42"))
_cOperRemessa   := RIGHT(_cOperTriangular,2)

SC5->( DBSetOrder(1) )
//ESSE While TRATA TANTO A EXCLUIDO DA CARGA DE CARREGAMENTO QUANTO A CARGA DE FATURAMENTO
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	DAK->( DBGoTo( (_cAlias)->REC_DAK) )
	DAI->( DBGoTo( (_cAlias)->REC_DAI) )

	If !SC5->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_PEDIDO ) )
		(_cAlias)->( DBSkip() )
		Loop
	EndIf

	If SC5->C5_I_OPER = _cOperRemessa
		aAdd(_aPeds_Triag,  SC5->(RECNO()) )
	EndIf

	If lCarga_Digitada .And. (!_lAchouCarga .Or. !_lAchouSC9) .And. !Empty(SC5->C5_I_CARGA) .And. DAK->DAK_COD # SC5->C5_I_CARGA //Por garantia pois posso tá lendo registros deletados do DAI e DAK
		(_cAlias)->( DBSkip() )
		Loop
	EndIf

	_lCargaTemAlteracao:=.F.

	If SC5->C5_I_TRCNF = 'S' .And. SC5->C5_I_FILFT # SC5->C5_I_FLFNC .And. !Empty(SC5->C5_I_PDPR) .And. !Empty(SC5->C5_I_PDFT)//Pedidos de Troca Nota
		If SC5->C5_NUM == SC5->C5_I_PDPR//Pedidos da Carga Carregamento
			//                  Codigo do DAK, Recno do DAI
			aAdd(_aPeds_Prod, { DAI->DAI_COD , DAI->(RECNO()) , SC5->(RECNO()),SC5->C5_I_FLFNC+" "+SC5->C5_I_PDPR,SC5->C5_I_FILFT+" "+SC5->C5_I_PDFT,SC5->C5_FILIAL+" "+SC5->C5_I_NPALE} )
			_lCargaTemAlteracao:=.T.

		ElseIf SC5->C5_NUM == SC5->C5_I_PDFT//Pedidos da Carga Faturamento **Na carga de Faturamento só vai ter troca nota**
			_cFilCarregamento:=SC5->C5_I_FLFNC
			_cPedCarregamento:=SC5->C5_I_PDPR
			SC5->( DBSeek( _cFilCarregamento + _cPedCarregamento ))//Posiciono no Pedido de Carregamento para pegar a carga da filial de carregamento
			_cCargaCarregamento:=_cFilCarregamento+SC5->C5_I_CARGA //A carga fica na filial de carregamento

			SC5->(DBSetOrder(1))
			DAI->(DBSetOrder(1)) //DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
			If DAI->(DBSeek(_cCargaCarregamento))
				//LENDO CARGA DE CARREGAMENTO
				While DAI->(!Eof()) .And. DAI->DAI_FILIAL+DAI->DAI_COD ==_cCargaCarregamento

					If !SC5->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_PEDIDO ) )
						DAI->( DBSkip() )
						Loop
					EndIf

					If SC5->C5_I_TRCNF = 'S' .And. SC5->C5_I_FILFT # SC5->C5_I_FLFNC .And. !Empty(SC5->C5_I_PDPR) .And. !Empty(SC5->C5_I_PDFT)//Pedidos de Troca Nota

						If SC5->C5_I_FILFT == cFilAnt//Verifico a filial de faturamento pq pode ter pedidos de filiais de faturmento diferentes na mesma carga
							//5 Recno do PV de Faturamento
							aAdd(_aNF_Fat , { DAI->(RECNO()) , SC5->(RECNO()) , SC5->C5_I_FLFNC+" "+SC5->C5_I_PDPR , SC5->C5_I_FILFT+" "+SC5->C5_I_PDFT, 0 } )
							_cNFEs  +=AllTrim(DAI->DAI_NFISCA)+" "+AllTrim(DAI->DAI_SERIE)+CRLF

							If SC5->( DBSeek( SC5->C5_I_FILFT+SC5->C5_I_PDFT ) )//Posiciona o Pedido de Faturamento
								_aNF_Fat[Len(_aNF_Fat),5] := SC5->(RECNO())
								aAdd(_aPeds_Fat , { SC5->(RECNO()),DAI->DAI_COD,SC5->C5_I_FLFNC+" "+SC5->C5_I_PDPR,SC5->C5_I_FILFT+" "+SC5->C5_I_PDFT} )
								_cPVFats+=AllTrim(SC5->C5_I_PDFT)+CRLF
							EndIf
						EndIf
					EndIf
					DAI->(DBSkip())
				EndDo
				//LENDO CARGA DE CARREGAMENTO
			EndIf

			Exit //Basta pegar a carga antiga de um dos pedidos da carga da faturamento
		EndIf
	ElseIf (!_lAchouCarga .Or. !_lAchouSC9) .And. SC5->C5_I_TRCNF # 'S' .And. SC5->C5_I_PEDPA = "S" .And. SC5->C5_I_PEDGE # "S" .And. !Empty(SC5->C5_I_NPALE)//Pedidos de Pallet gerados sem troca nota **Na carga de Faturamento só vai ter troca nota**
		//                  Codigo do DAK, Recno do DAI
		aAdd(_aPeds_Prod, { DAI->DAI_COD , DAI->(RECNO()) , SC5->(RECNO()),SC5->C5_FILIAL+" "+SC5->C5_NUM ,SC5->C5_FILIAL+" "+SC5->C5_I_NPALE} )
	EndIf

	If _lCargaTemAlteracao .And. _lAchouCarga
		If aScan(_aCargaAcerta, DAI->DAI_FILIAL+DAK->DAK_COD ) = 0
			aAdd(_aCargaAcerta, DAI->DAI_FILIAL+DAK->DAK_COD )//Lista de Cargas para acertar
		EndIf
	EndIf

	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )
DBSelectArea("DAK")

If Len(_aPeds_Prod) = 0 .And. Len(_aNF_Fat) = 0 .And. Len(_aPeds_Fat) = 0 .And. Len(_aPeds_Triag) = 0
	If lCarga_Digitada
		_cProblema:="Nao existem pedidos de Carregamento / Faturamentos gerados nessa carga para excluir."
		_cSolucao :="Selecione uma carga que tenha pedido de troca nota e que ocorreu algum ploblema na exclusão da(s) nota(s)."
		_lAchouCarga:=.F.
		If DAK->( DBSeek( _cFilCarga+_cCargaExclui+_cSeqCarga ) )
			If !DAI->( DBSeek( _cFilCarga+_cCargaExclui+_cSeqCarga ) )
				_lAchouCarga:=.T.
				_cSolucao :="Esta carga esta sem pedidos (DAI). Será apagado todos os dados de capa (DAK) referente a essa carga."
			ElseIf !Empty(DAI->DAI_NFISCA)//Se chegou nesse ponto é pq não tem nenhuma nota com esse numero da carga isso não quer dizer que a nota não esteja vinculada para outra carga
				_lAchouCarga:=.T.
				_cSolucao :="Esta carga não esta em nenhuma nota. Será apagado todos os dados de nota (DAI_NFISCA) referente a essa carga para liberar o estorno da mesma."
			EndIf
		EndIf
		xMagHelpFis("Atenção (OM521BRW) 004",_cProblema,_cSolucao)
	EndIf

	If !_lAchouCarga
		Return .F.
	EndIf
EndIf

_nEscolha:=0
If !Empty(_cCargaCarregamento) .And. Len(_aNF_Fat) # 0//Só entra aqui na exclusao da CARGA de faturamento
	//ESCOLHE SE EXCLUI TUDO ATE AS NFES
	_nEscolha := OpcExclusao(_cCargaExclui,lCarga_Digitada)
	If _nEscolha = 0
		Return .F.
	EndIf
	//ESCOLHE SE EXCLUI TUDO ATE AS NFES
EndIf

_lOK   := .T.
_aLog  := {}
_lDeuErro:= .F.//Se der algum Erro
_cTitSA2:='Cliente'

BEGIN Transaction
	Begin Sequence

		Private _lDeuErro:= .F.//Se der algum Erro

		If Len(_aPeds_Triag) > 0
			For P := 1 TO Len(_aPeds_Triag)
				SC5->(DBGoTo( _aPeds_Triag[P] ) )
				For nInc := 1 To SC5->(FCount())
					M->&(SC5->(FieldName(nInc))) := SC5->(FieldGet(nInc))
				Next
				Processa( {|| _lDeuErro:=U_IT_OperTriangular(SC5->C5_NUM,.T.,.F.) } ,"Excluindo Pedido de Faturamento...", "Excluindo Ped. Fat. da Remessa: "+SC5->C5_NUM+"... " )
				If _lDeuErro
					DisarmTransaction()
					BREAK
				EndIf
			Next
		EndIf

		// Array que controla os Pedidos de Origem lincados com o Pedidos novos de Carregamento e Pallet
		aLink_POV_PON :={}//Link Pedido Velho Pedido Novo
		_aLog  := {}

		If Len(_aPeds_Prod) # 0 //TRATA QUANDO É CARGA DE CARREGAMENTO
			Processa( {|| ExcluiPedGerados(_aPeds_Prod)   } ,, "Estornando Pedidos de Carregamento..." )
			Processa( {|| VoltaGerPedFaturamento(aLink_POV_PON) } ,, "Volta Pedidos de Faturamento..." )

			If !_lDeuErro .And. Len(_aCargaAcerta) > 0 //_lAchouCarga
				Processa( {|| AcertaCarga(_aCargaAcerta)  } ,, "Acertando Cargas..." )
			EndIf
		ElseIf (Len(_aNF_Fat) # 0 .Or. !Empty(_cCargaCarregamento)) .Or. Len(_aPeds_Fat) # 0 //TRATA QUANDO É CARGA DE FATURAMENTO
			If !Empty(_cCargaCarregamento) .And. _nEscolha = 2//Mantem/Regera a Carga com o mesmo numero
				//ESSA FUNCAO TA NO RDMAKE MT103FIM.PRW - Quando entra aqui mostra o log lá dentro e zera o _aLog e disarma a transação tudo lá dentro
				Processa( {|| _lDeuErro:=!U_MT103GerCarga(_cCargaCarregamento,.T.,_cCargaExclui)  } ,, "Regeração de Carga..." )//AWF-TN-26/09/2016-
			ElseIf Len(_aNF_Fat) # 0 .And. _nEscolha = 1//Exclui as NFES de entrada
				Processa( {|| Exclui_NF(_aNF_Fat) } ,, "Exclui NFEs Classificadas..." )//AWF-01/11/2016
				_cTitSA2:='Fornecedor'
			ElseIf Len(_aPeds_Fat) # 0 .And. _nEscolha = 3//Volta Pedidos de Faturamento
				Processa( {|| VoltaPedFaturamento(_aPeds_Fat) } ,, "Liberando Estoque Pedidos de Faturamento..." )//AWF-22/12/2016
			EndIf
		EndIf

		If _lDeuErro
			DisarmTransaction()
		ElseIf _nEscolha # 2
			M520DelCarga(_cFilCarga,_cCargaExclui,_cSeqCarga)
		EndIf
	End Sequence
END Transaction

//Garante commit e liberação de locks
Dbcommit()
Dbcommitall()
Dbunlock()

If Len(_aLog) > 0
	_bOK:=NIL
	If _lDeuErro
		_cProblema:="Ocorreram problemas no Estorno dos Pedidos de Troca Nota da Carga, para maiores detalhes veja a Coluna Movimentação."
		_cSolucao :="Para fechar a tela de Log clique no Botão FECHAR. Todas as Movimentações não poderam ser salvas."
		_bOK:={|| xMagHelpFis("Atenção (OM521BRW) 005",_cProblema,_cSolucao) , .F. }
	EndIf

	If GETMV("MV_GERLOGC",,.T.)
		U_ITGERARQ( 'Log do Estorno da Carga (OM521BRW) 009' , {" ",'Carga','Movimentação',_cTitSA2,'Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} , _aLog , "EC_"+_cCargaExclui+"_" )
	EndIf

	_lOK:=U_ITListBox( 'Log do Estorno da Carga (OM521BRW) 010' ,;
		{" ",'Carga','Movimentação',_cTitSA2,'Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'},_aLog,.T.,4,,,;
		{ 10,     40,           200,     150,                   60,                   60,                  60,                  60},, _bOK )
EndIf

DBSelectArea("DAK")

Return (_lOK .And. !_lDeuErro)

/*
===============================================================================================================================
Programa--------: ExcluiPedGerados(_aPeds_Prod)
Autor-----------: Alex Wallauer
Data da Criacao-: 29/09/2016
Descrição-------: Exclui Pedidos Gerados
Parametros------: _aPeds_Prod: Lista dos pedidos
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================
*/
Static Function ExcluiPedGerados(_aPeds_Prod)

Local _Ped,_nLog,lErroSC9,_cLocal
Local _aCabPV  :={}
Local _aItemPV :={}
Local _aItensPV:={}
Local _aLogAux :={}
Local _aLog1Aux:={}
Local _aGuardaLocal:={}
Local _cCliente:=_cMensagem:=""
Local _lAchouSC9 := .F.

SC6->( DBSetOrder(1) )
SC9->( DBSetOrder(1) )

ProcRegua(Len(_aPeds_Prod))

For _Ped := 1 TO Len(_aPeds_Prod)//Codigo do DAK, Recno do DAI ,Recno do Pedido de Gerado

	DAI->( DBGoTo( _aPeds_Prod[_Ped,2] ))//Recno do DAI

	IncProc("Excluindo Pedido: "+DAI->DAI_PEDIDO)

	If !SC5->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_PEDIDO ) )
		Loop
	EndIf

	If SC5->C5_I_TRCNF # 'S'
		If SC5->C5_I_PEDPA == "S" .And. SC5->C5_I_PEDGE # "S"//Retesta por garantia
			_cCliente   :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )
			// Array que controla os Pedidos de Pallet a ser excluidos
			//1-Filial de Origem,2-Pedido de Origem,3-Recno do DAI   ,4-Filial Gerada,5-Pedido Gerado,6-Cliente  ,7-Armazem,8-GL,9-Pedido Paletizado
			aAdd(aLink_POV_PON, { SC5->C5_FILIAL , SC5->C5_NUM      ,  DAI->(RECNO()) , ""            , ""            , _cCliente ,""       , {} ,SC5->C5_FILIAL+" "+SC5->C5_I_NPALE} )
		EndIf
		Loop
	EndIf

	SC5->( DBGoTo( _aPeds_Prod[_Ped,3] ))//Recno do Pedido de Gerado

	_lPedPallat:=(SC5->C5_I_PEDPA == "S" .And. SC5->C5_I_PEDGE # "S")
	_lAchouSC9:=.F.

	If _lAchouCarga
		// Limpa a carga do DAI para nao dar mensagem de erro customizada no estorno da liberacao
		DAI->(RecLock("DAI",.F.))
		DAI->DAI_PEDIDO := ""
		DAI->(MSUnLock())

		// Limpa a carga do SC9 para nao dar mensagem de erro padrao no estorno da liberacao
		SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
		While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO) == SC5->C5_FILIAL + SC5->C5_NUM
			SC9->( RecLock('SC9',.F.) )
			SC9->C9_CARGA:=""
			SC9->C9_SEQCAR:=""
			SC9->C9_SEQENT:=""
			SC9->( MSUnLock() )
			SC9->( DBSkip() )
			_lAchouSC9:=.T.
		EndDo
	EndIf

	_aCabPV   :={}
	_aItemPV  :={}
	_aItensPV :={}
	_dDtEnt	  :=If(SC5->C5_I_DTENT < DATE(),DATE(),SC5->C5_I_DTENT)//Para nao travar a alteracao do Pedido de Pallet
	// Monta o cabeçalho do pedido
	aAdd( _aCabPV, { "C5_FILIAL"	,SC5->C5_FILIAL  , Nil})//filial
	aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM	 , Nil})
	aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil})//Tipo de pedido
	aAdd( _aCabPV, { "C5_I_OPER"	,SC5->C5_I_OPER  , Nil})//Tipo da operacao
	aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL})//Codigo do cliente
	aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT	 , Nil})
	aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL})//Loja para entrada
	aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL})//Loja do cliente
	aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL})//Data de emissao
	aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP	 , Nil})
	aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL})//Codigo da condicao de pagamanto*
	aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1	 , Nil})
	aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil})//Moeda
	aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD	 , Nil})
	aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL})//Liberacao Total
	aAdd( _aCabPV, { "C5_TIPLIB"  	,SC5->C5_TIPLIB  , Nil})//Tipo de Liberacao
	aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL})//Tipo do Cliente
	aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL})//Numero que originou a pedido de palete
	aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL})//Pedido Refere a um pedido de Pallet
	aAdd( _aCabPV, { "C5_I_DTENT"	,_dDtEnt         , Nil})//Dt de Entrega
	aAdd( _aCabPV, { "C5_I_TRCNF"   ,SC5->C5_I_TRCNF , Nil})
	aAdd( _aCabPV, { "C5_I_BLPRC"   ,SC5->C5_I_BLPRC , Nil})
	aAdd( _aCabPV, { "C5_I_FILFT"   ,SC5->C5_I_FILFT , Nil})
	aAdd( _aCabPV, { "C5_I_FLFNC"   ,SC5->C5_I_FLFNC , Nil})
	// Monta o item do pedido
	SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
	_cLocal  :=SC6->C6_LOCAL
	_aGuardaLocal:={}

	While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
		_aItemPV:={}

		aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
		aAdd( _aItemPV , { "C6_NUM"    	,SC6->C6_NUM	 , Nil })
		aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
		aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
		aAdd( _aItemPV , { "C6_UNSVEN"  ,SC6->C6_UNSVEN  , Nil }) // Quantidade Vendida 2 un
		aAdd( _aItemPV , { "C6_QTDVEN"  ,SC6->C6_QTDVEN  , Nil }) // Quantidade Vendida
		aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
		aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
		aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
		aAdd( _aItemPV , { "C6_LOJA"   	,SC6->C6_LOJA	 , Nil })
		aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
		aAdd( _aItemPV , { "C6_VALOR"   ,SC6->C6_VALOR   , Nil }) // valor total do item
		aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
		aAdd( _aItemPV , { "C6_TES"    	,SC6->C6_TES	 , Nil })
		aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
		aAdd( _aItemPV , { "C6_CF"     	,SC6->C6_CF		 , Nil })
		aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
		aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
		aAdd( _aItemPV , { "C6_PEDCLI" 	,SC6->C6_PEDCLI	 , Nil })
		aAdd( _aItemPV , { "C6_I_BLPRC"	,SC6->C6_I_BLPRC , Nil })

		aAdd( _aItensPV ,_aItemPV )
		aAdd( _aGuardaLocal , { SC6->C6_ITEM,SC6->C6_LOCAL,SC6->C6_TES } )

		SC6->( DBSkip() )
	EndDo
	// ALTERAÇÃO do pedido de Carregamento Gerados para liberar o estoque (Troca NF)
	lMsErroAuto:=.F.
	lErroSC9:=.F.

	If _lAchouSC9
		MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )// ALTERAÇÃO do pedido de Carregamento Gerados para liberar o estoque (Troca NF)

		SC5->( DBGoTo( _aPeds_Prod[_Ped,3] ))//Recno do Pedido
		_cCliente   :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )

		SC9->( DBSetOrder(1) )
		If lMsErroAuto .Or. ( lErroSC9:=SC9->( DBSeek( SC5->C5_FILIAL+SC5->C5_NUM ) ))//Se liberou o estoque nao pode achar no SC9, portanto se char é um erro
			If lErroSC9
				_cMensagem:="Erro ao Estornar a liberação do Pedido Gerado"+If(_lPedPallat," de Pallet","")+" (Troca NF), ainda tem dados de liberacao (SC9)."
			Else
				_cMensagem:="Erro: ["+AllTrim(MostraErro())+"]"
				_cMensagem:='Erro ao Estornar a liberação do Pedido Gerado'+If(_lPedPallat," de Pallet","")+" (Troca NF), "+_cMensagem
			EndIf

			//  aAdd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
			aAdd( _aLog , {.F.,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_I_PDPR       ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )
		Else
			_lAchouSC9:=.F.
		EndIf
	EndIf

	If !_lAchouSC9
		_cMensagem:='Estornou a liberação do Pedido Gerado'+If(_lPedPallat," de Pallet","")+" (Troca NF)"
		//  aAdd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.T.,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_I_PDPR       ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )
	EndIf
	// ALTERAÇÃO do pedido de Carregamento Gerados para liberar o estoque (Troca NF)

	// ESTORNO do pedido de Carregamento Gerado (Troca NF)
	_cMensagem:='Estornou o Pedido Gerado'+If(_lPedPallat," de Pallet","")+" (Troca NF)"

	//(_aLog ,{" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
	_aLogAux:={.T.,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_I_PDPR       ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT}

	// Array que controla os Pedidos de Origem lincados com o Pedidos gerados de Carregamento
	//1-Filial de Origem,2-Pedido de Origem,3-Recno do DAI  ,4-Filial Gerada   ,5-Pedido Gerado  ,6-Cliente ,7-Armazem,8-Guarda Locais
	aAdd(aLink_POV_PON, { SC5->C5_I_FILFT, SC5->C5_I_PDFT   ,  DAI->(RECNO()),  SC5->C5_I_FLFNC ,  SC5->C5_I_PDPR , _cCliente, _cLocal , ACLONE(_aGuardaLocal) } )

	MSEXECAUTO({|x,y,z| MATA410(x,y,z)}, _aCabPV , _aItensPV ,5)// ESTORNO do pedido de Carregamento Gerado (Troca NF)

	If lMsErroAuto
		_cMensagem:="Erro: ["+AllTrim(MostraErro())+"]"
		_cMensagem:='Erro ao Estornar o Pedido Gerado'+If(_lPedPallat," de Pallet","")+" (Troca NF) ,"+_cMensagem
		SC5->( DBGoTo( _aPeds_Prod[_Ped,3] ))//Recno do Pedido Gerado

		// aAdd( _aLog     , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog1Aux , {.F.,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_I_PDPR       ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )

		_lDeuErro:=.T.//Se der algum Erro
		Loop
	Else
		aAdd( _aLog1Aux , _aLogAux )
	EndIf
	// ESTORNO do pedido de Carregamento Gerado (Troca NF)
Next

For _nLog := 1 TO Len(_aLog1Aux)
	aAdd( _aLog , _aLog1Aux[_nLog] )
Next

Return .T.

/*
===============================================================================================================================
Programa--------: VoltaGerPedFaturamento()
Autor-----------: Alex Wallauer
Data da Criacao-: 30/09/2016
Descrição-------: Volta os pedidos de Faturmento para o carregamento
Parametros------: aLink_POV_PON: { SC5->C5_I_FILFT,SC5->C5_I_PDFT,DAI->(RECNO()),SC5->C5_I_FLFNC,SC5->C5_I_PDPR,_cCliente,_cLocal,ACLONE(_aGuardaLocal)}
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================
*/
Static Function VoltaGerPedFaturamento(aLink_POV_PON)

Local _Ped,_nQtdLib,_cCliente,_cMensagem
Local lErroSC9:=.F.,_lOK:=.T.
Local _aLog1Aux:={}
Local _aLog2Aux:={}
Local _aRec_SC6:={}
Local _aGuardaLocal:={}
Local _ccodusr := RetCodUsr()
Local _nRec		:= 0
Local _nLog		:= 0
Local _cTot    := AllTrim(Str(Len(aLink_POV_PON)))

ProcRegua(Len(aLink_POV_PON))

For _Ped := 1 TO Len(aLink_POV_PON)// 1-Filial de Origem, 2-Pedido de Origem, 3-Recno do DAI   ,4-Filial Gerada    , 5-Pedido Gerado ,6-cCliente,7-Armazem

	DAI->( DBGoTo( aLink_POV_PON[_Ped,3] ))

	IncProc("Voltando Pedido: "+aLink_POV_PON[_Ped,1]+"-"+aLink_POV_PON[_Ped,2]+" / " +StrZero(_Ped,3) +" de "+ _cTot )

	SC5->( DBSetOrder(1) )//Os DBSetOrder estao dentro do For por causa do MSExec Auto ()
	SC6->( DBSetOrder(1) )
	SC9->( DBSetOrder(1) )

	If !SC5->( DBSeek( aLink_POV_PON[_Ped,1]+aLink_POV_PON[_Ped,2] ) )//Posiciona no Pedido de Faturamento que era o velho de Carregamento
		_cMensagem:='Aviso - Pedido Original nao Encontrado no Faturamento: '+aLink_POV_PON[_Ped,1]+" "+aLink_POV_PON[_Ped,2]
		//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente'            ,'Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.F.,DAI->DAI_COD,_cMensagem    ,aLink_POV_PON[_Ped,6],aLink_POV_PON[_Ped,4],aLink_POV_PON[_Ped,5],aLink_POV_PON[_Ped,1],aLink_POV_PON[_Ped,2]} )
		Loop
	EndIf

	_lPedTrocaNF:=(SC5->C5_I_TRCNF == "S")
	_lPedPallat :=(SC5->C5_I_PEDPA == "S" .And. SC5->C5_I_PEDGE # "S")

	//TRATAMENTO PARA PEDIDOS DE TROCA NOTA NOTA
	If _lPedTrocaNF

		//TRANSFERINDO DE FILIAL
		If SC9->( DBSeek( aLink_POV_PON[_Ped,1]+aLink_POV_PON[_Ped,2] ) )   //Posiciona no SC9 do Pedido de Faturamento que era o velho de Carregamento // SC5->C5_I_TRCNF ='S' .And.
			_cMensagem:='Pedido de Origem '+If(_lPedPallat," de Pallet","")+' (Troca NF), possui Doc. Classificado na Filial de Faturamento (SC9)'
			//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente'            ,'Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
			aAdd( _aLog , {.F.,DAI->DAI_COD,_cMensagem    ,aLink_POV_PON[_Ped,6],aLink_POV_PON[_Ped,4],aLink_POV_PON[_Ped,5],aLink_POV_PON[_Ped,1],aLink_POV_PON[_Ped,2]} )
			_lDeuErro:=.T.//Se der algum Erro
			Loop
		EndIf

		SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
		_aRec_SC6:={}
		While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
			aAdd(_aRec_SC6, SC6->( Recno() ) )
			SC6->( DBSkip() )
		EndDo

		_nRecSC5FilAtual:=SC5->( Recno() )

		SC5->( RecLock( 'SC5' , .F. ) )
		SC5->C5_FILIAL := SC5->C5_I_FLFNC//Volta a filial
		SC5->C5_I_PDFT := "" // Limpa Pedido de Origem (codigo é o mesmo só que na filial de faturamento agora)
		SC5->C5_I_PDPR := "" // Limpa Código do Pedido novo de Carregamento
		SC5->C5_I_CARGA:= "" // Limpa o numero da Carga de Origem para usar mais para frente
		SC5->( MSUnLock() )

		_aGuardaLocal:=ACLONE(aLink_POV_PON[_Ped,8])

		For _nRec := 1 to Len(_aRec_SC6)
			SC6->( DBGoTo( _aRec_SC6[_nRec] ))//Recno do Pedido de Origem de Troca Nota
			SC6->( RecLock( 'SC6' , .F. ) )
			SC6->C6_FILIAL := SC5->C5_I_FLFNC
			If (_nLoc:=aScan(_aGuardaLocal, {|X| X[1] == SC6->C6_ITEM } )) # 0
				SC6->C6_LOCAL:= _aGuardaLocal[_nLoc,2]
				SC6->C6_TES  := _aGuardaLocal[_nLoc,3]//Não adianta volta a TES não é a mesma de antes pq a operação e cliente são diferentes na copia
			EndIf
			SC6->( MSUnLock() )

		Next

		_cCliente   :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )
		_cMensagem:='Tranferencia do pedido de Faturamento'+If(_lPedPallat," de Pallet","")+" (Troca NF)"

		//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.T.,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_NUM          ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )

		// Grava o LOG de traferencia do Pedidos Novo
		_aDadIni := {}
		aAdd( _aDadIni , { 'C5_FILIAL'	, SC5->C5_FILIAL	, ''		} )
		aAdd( _aDadIni , { 'C5_NUM'		, SC5->C5_NUM		, ''		} )
		aAdd( _aDadIni , { 'C5_CLIENTE'	, SC5->C5_CLIENTE	, ''		} )
		aAdd( _aDadIni , { 'C5_LOJACLI'	, SC5->C5_LOJACLI	, ''		} )
		aAdd( _aDadIni , { 'C5_EMISSAO'	, SC5->C5_EMISSAO	, SToD('')	} )
		aAdd( _aDadIni , { 'C5_I_DTENT'	, SC5->C5_I_DTENT	, SToD('')	} )
		U_ITGrvLog( _aDadIni , 'SC5' , 1 , SC5->( C5_FILIAL + C5_NUM ) , 'T' , _ccodusr )
		// Grava o LOG de traferencia do Pedidos Novo
		//TRANSFERINDO DE FILIAL

		If _lAchouCarga .Or. !_lPedPallat//Se tem carga faz sempre senão só quando não é PV de Pallet

			//ALTERA A TES DO PEDIDO DEPOIS DE TRENFERIR
			SC5->( DBGoTo( _nRecSC5FilAtual ))//Recno do Pedido Transferido de Troca Nota

			_aCabPV  :={}
			_aItemPV :={}
			_aItensPV:={}
			_dDtEnt  := If(SC5->C5_I_DTENT < DATE(),DATE(),SC5->C5_I_DTENT)//Para nao travar a exclusao do Pedido de Pallet
			// Monta o cabeçalho do pedido
			aAdd( _aCabPV, { "C5_FILIAL"	,SC5->C5_FILIAL  , Nil})//filial
			aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM     , Nil})
			aAdd( _aCabPV, { "C5_TIPO"	   ,SC5->C5_TIPO    , Nil})//Tipo de pedido
			aAdd( _aCabPV, { "C5_I_OPER"	,SC5->C5_I_OPER  , Nil})//Tipo da operacao
			aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL})//Codigo do cliente
			aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT  , Nil})
			aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL})//Loja para entrada
			aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL})//Loja do cliente
			aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL})//Data de emissao
			aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP  , Nil})
			aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL})//Codigo da condicao de pagamanto*
			aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1   , Nil})
			aAdd( _aCabPV, { "C5_MOEDA"	,SC5->C5_MOEDA   , Nil})//Moeda
			aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD  , Nil})
			aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL})//Liberacao Total
			aAdd( _aCabPV, { "C5_TIPLIB"  ,SC5->C5_TIPLIB  , Nil})//Tipo de Liberacao
			aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL})//Tipo do Cliente
			aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL})//Numero que originou a pedido de palete
			aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL})//Pedido Refere a um pedido de Pallet
			aAdd( _aCabPV, { "C5_I_DTENT"	,_dDtEnt         , Nil})//Dt de Entrega
			aAdd( _aCabPV, { "C5_I_TRCNF" ,SC5->C5_I_TRCNF , Nil})
			aAdd( _aCabPV, { "C5_I_BLCRE" ,SC5->C5_I_BLCRE , Nil})
			aAdd( _aCabPV, { "C5_I_BLPRC" ,SC5->C5_I_BLPRC , Nil})
			aAdd( _aCabPV, { "C5_I_FILFT" ,SC5->C5_I_FILFT , Nil})
			aAdd( _aCabPV, { "C5_I_FLFNC" ,SC5->C5_I_FLFNC , Nil})

			// Monta o item do pedido
			SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

			While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
				_aItemPV:={}

				aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
				aAdd( _aItemPV , { "C6_NUM"    	,SC6->C6_NUM	 , Nil })
				aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
				aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
				aAdd( _aItemPV , { "C6_UNSVEN"  ,SC6->C6_UNSVEN  , Nil }) // Quantidade Vendida 2 un
				aAdd( _aItemPV , { "C6_QTDVEN"  ,SC6->C6_QTDVEN  , Nil }) // Quantidade Vendida
				aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
				aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
				aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
				aAdd( _aItemPV , { "C6_LOJA"   	,SC6->C6_LOJA	 , Nil })
				aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
				aAdd( _aItemPV , { "C6_VALOR"   ,SC6->C6_VALOR   , Nil }) // valor total do item
				aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
				aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
				aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
				aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
				aAdd( _aItemPV , { "C6_PEDCLI" 	,SC6->C6_PEDCLI	 , Nil })
				aAdd( _aItemPV , { "C6_I_BLPRC"	,SC6->C6_I_BLPRC , Nil })
				aAdd( _aItemPV , { "C6_I_VLIBP"	,SC6->C6_I_VLIBP , Nil }) // Preco Liberado
				aAdd( _aItensPV ,_aItemPV )

				SC6->( DBSkip() )
			EndDo
			lMsErroAuto:=.F.
			_cCargaAchou:=""//Caso ache o pedido que  esta voltando em outra carga, preenchida no rdmake MT410ACE.PRW

			// Alteração da TES do pedido de Faturamento
			MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )// Alteração da TES do pedido de Faturamento

			SC5->( DBGoTo( _nRecSC5FilAtual ))//Recno do Pedido Transferido de Troca Nota
			_cCliente   :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )
			_lOK:=.T.
			lErroSC9:=.F.
			SC9->( DBSetOrder(1) )
			If lMsErroAuto .Or. ( lErroSC9:=SC9->( DBSeek( SC5->C5_FILIAL+SC5->C5_NUM ) ))//Se liberou o estoque nao pode achar no SC9, portanto se achar é um erro
				If lErroSC9
					_cMensagem:="Erro ao Recuperar a TES do pedido"+If(_lPedPallat," de Pallet","")+" (Troca NF), ainda tem dados de liberacao (SC9)."
				Else
					_cMensagem:="Erro: ["+AllTrim(MostraErro())+"]"
					_cMensagem:='Erro ao Recuperar a TES do pedido'+If(_lPedPallat," de Pallet","")+" (Troca NF), "+_cMensagem
				EndIf
				_lOK:=.F.
				_lDeuErro:=.T.//Se der algum Erro
			Else
				If !Empty(_cCargaAchou)
					DAI->(DBSetOrder(4)) //DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
					If DAI->(DBSeek(_cCargaAchou))
						_cCargaAchou:=DAI->(DAI_FILIAL+DAI_COD+DAI_SEQCAR)
						DAI->(RecLock("DAI",.F.))
						DAI->(DBDELETE())
						DAI->(MSUnLock())
						_cMensagem:='Pedido estava vinculado a ourta carga. Desvinculado com sucesso'
						//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
						aAdd( _aLog , {.T.,DAI->DAI_COD,_cMensagem    ,""       ,DAI->DAI_FILIAL      , DAI->DAI_PEDIDO     ,""                  ,""            } )

						DAK->( DBSetOrder(1) ) //DAK_FILIAL+DAK_COD+DAK_SEQCAR
						DAI->( DBSetOrder(1) )
						If !DAI->( DBSeek( _cCargaAchou ) )
							If DAK->( DBSeek( _cCargaAchou ) ) //Tem casos que os estorno deleta a carga e tem casos que nao POR CAUSA DE ALGUM ERRO NA EXLCUSO PADRAO
								DAK->(RecLock("DAK",.F.))
								DAK->(DBDELETE())
								DAK->(MSUnLock())
								_cMensagem:='Capa da carga (DAK) apagada com sucesso ('+DAK->DAK_FILIAL+' '+DAK->DAK_COD+' '+DAK->DAK_SEQCAR+')'
								//aAdd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
								aAdd( _aLog , {.T.,DAI->DAI_COD,_cMensagem    ,""       ,""                   ,""                   ,""                  ,""            } )
							EndIf
						ElseIf DAK->( DBSeek( _cCargaAchou ) ) //Tem casos que os estorno deleta a carga e tem casos que nao POR CAUSA DE ALGUM ERRO NA EXLCUSO PADRAO
							If aScan(_aCargaAcerta, DAI->DAI_FILIAL+DAI->DAI_COD ) = 0
								aAdd(_aCargaAcerta, DAI->DAI_FILIAL+DAI->DAI_COD )//Lista de Cargas para acertar
							EndIf
						EndIf
					EndIf
				EndIf

				SC5->( RecLock( 'SC5' , .F. ) )
				If (_nPos:=aScan(_aCabPV, {|C| C[1]=="C5_I_BLPRC" } )) # 0
					SC5->C5_I_BLPRC:= _aCabPV[ _nPos, 2 ]
				EndIf
				If (_nPos:=aScan(_aCabPV, {|C| C[1]=="C5_I_BLCRE" } )) # 0
					SC5->C5_I_BLCRE:= _aCabPV[ _nPos , 2 ]
				EndIf
				SC5->( MSUnLock() )
				SC6->( DBSetOrder(1) )
				SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
				//Grava liberações de preços nos itens do pedido de carregamento
				While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
					_nLin1:=aScan(_aItensPV[1], {|I| I[1]== "C6_ITEM"  } )
					_nItem:=aScan(_aItensPV   , {|I| I[_nLin1,2]== SC6->C6_ITEM  } )
					_nLin2:=aScan(_aItensPV[1], {|I| I[1]== "C6_I_BLPRC"  } )
					_nLin3:=aScan(_aItensPV[1], {|I| I[1]== "C6_I_VLIBP"  } )

					SC6->( RecLock( 'SC6' , .F. ) )
					If _nItem # 0 .And. _nLin2 # 0
						SC6->C6_I_BLPRC := _aItensPV[_nItem,_nLin2, 2 ]
					EndIf
					If _nItem # 0 .And. _nLin3 # 0
						SC6->C6_I_VLIBP := _aItensPV[_nItem,_nLin3, 2 ]
					EndIf
					SC6->( MSUnLock() )
					SC6->( DBSkip())
				EndDo
				_cMensagem:='Recuperada a TES do pedido'+If(_lPedPallat," de Pallet","")+" (Troca NF)"
			EndIf

			//aAdd( _aLog  , {" " ,'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
			aAdd( _aLog2Aux, {_lOK,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_NUM          ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )
		EndIf
		//ALTERA A TES DO PEDIDO DEPOIS DE TRENFERIR

	EndIf
	//TRATAMENTO PARA PEDIDOS DE TROCA NOTA NOTA

	// Liberacão de Pedido
	If _lAchouCarga .And. _lPedTrocaNF//SÓ QUANDO TIVER CARGA

		SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

		lMsErroAuto:=.F.

		While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
			If !SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
				_nQtdLib := MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN)//LIBERA PEDIDO
			Else
				_nQtdLib := SC9->C9_QTDLIB
			EndIf

			If _nQtdLib # SC6->C6_QTDVEN
				lMsErroAuto:=.T.
				Exit
			EndIf

			SC6->( DBSkip() )
		EndDo

		_cCliente  :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )

		lBloqEstoque:=lBloqCredito:=lErroSC9:=.F.
		If lMsErroAuto .Or. ( lErroSC9:=Ver_SC9(SC5->C5_FILIAL+SC5->C5_NUM) )
			If lErroSC9
				_cMensagem:='Erro ao liberar o Pedido de Carregamento'+If(_lPedPallat," de Pallet","")+" (Troca NF), mas com Bloqueio de"+If(lBloqEstoque," Estoque","")+If(lBloqCredito," Credito","")+" - Item: "+SC9->C9_PRODUTO
			Else
				_cMensagem:='Erro ao liberar o Pedido de Carregamento'+If(_lPedPallat," de Pallet","")+" (Troca NF)"
			EndIf

			//aAdd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
			aAdd( _aLog1Aux , {.F.,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_NUM          ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )

			_lDeuErro:=.T.//Se der algum Erro
			Loop
		Else
			_cMensagem:='Liberou Pedido de Carregamento'+If(_lPedPallat," de Pallet","")+" (Troca NF)"
			//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
			aAdd( _aLog1Aux , {.T.,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_NUM          ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )
		EndIf

		// Colocando o pedido na carga
		DAI->( DBGoTo( aLink_POV_PON[_Ped,3] ))

		DAI->(RecLock("DAI",.F.))
		DAI->DAI_PEDIDO := SC5->C5_NUM
		DAI->DAI_CLIENT := SC5->C5_CLIENTE
		DAI->DAI_LOJA   := SC5->C5_LOJACLI
		DAI->DAI_PESO   := SC5->C5_I_PESBR
		DAI->(MSUnLock())

		// Colocando a carga no SC9 do novo pedido
		SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

		While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO) == SC5->C5_FILIAL + SC5->C5_NUM
			SC9->( RecLock('SC9',.F.) )
			SC9->C9_CARGA :=DAI->DAI_COD
			SC9->C9_SEQCAR:=DAI->DAI_SEQCAR
			SC9->C9_SEQENT:=DAI->DAI_SEQUEN
			SC9->( MSUnLock() )
			SC9->( DBSkip() )
		EndDo
	ElseIf _lPedPallat //QUANDO NAO TIVER ou TIVER A CARGA TEM QUE EXCLUIR OS PEDIDOS DE PALLET SE NÃO TIVER SC9
		If SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
			_cMensagem:='Pedido de Pallet'+If(_lPedTrocaNF," (Troca NF)","")+' ainda possui Liberacao (SC9)'
			//dd( _aLog , {" ",'Carga '                                           ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
			aAdd( _aLog , {.F.,SC9->C9_CARGA+"-"+SC9->C9_SEQCAR+"-"+SC9->C9_SEQENT,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_NUM          ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )
			_lDeuErro:=.T.//Se der algum Erro
			Loop
		EndIf

		_aCabPV   :={}
		_aItemPV  :={}
		_aItensPV :={}
		_dDtEnt   := If(SC5->C5_I_DTENT < DATE(),DATE(),SC5->C5_I_DTENT)//Para nao travar a exclusao do Pedido de Pallet
		_cPedGerou:=SC5->C5_I_NPALE

		// Monta o cabeçalho do pedido de pallet
		aAdd( _aCabPV, { "C5_FILIAL"	,SC5->C5_FILIAL  , Nil})//filial
		aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM	 , Nil})
		aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil})//Tipo de pedido
		aAdd( _aCabPV, { "C5_I_OPER"	,SC5->C5_I_OPER  , Nil})//Tipo da operacao
		aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL})//Codigo do cliente
		aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT	 , Nil})
		aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL})//Loja para entrada
		aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL})//Loja do cliente
		aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL})//Data de emissao
		aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP	 , Nil})
		aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL})//Codigo da condicao de pagamanto*
		aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1	 , Nil})
		aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil})//Moeda
		aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD	 , Nil})
		aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL})//Liberacao Total
		aAdd( _aCabPV, { "C5_TIPLIB"  	,SC5->C5_TIPLIB  , Nil})//Tipo de Liberacao
		aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL})//Tipo do Cliente
		aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL})//Numero que originou a pedido de palete
		aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL})//Pedido Refere a um pedido de Pallet
		aAdd( _aCabPV, { "C5_I_DTENT"	,_dDtEnt         , Nil})//Dt de Entrega
		aAdd( _aCabPV, { "C5_I_TRCNF"   ,SC5->C5_I_TRCNF , Nil})
		aAdd( _aCabPV, { "C5_I_BLPRC"   ,SC5->C5_I_BLPRC , Nil})
		aAdd( _aCabPV, { "C5_I_FILFT"   ,SC5->C5_I_FILFT , Nil})
		aAdd( _aCabPV, { "C5_I_FLFNC"   ,SC5->C5_I_FLFNC , Nil})

		// Monta o item do pedido de pallet
		SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

		While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
			_aItemPV:={}

			aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
			aAdd( _aItemPV , { "C6_NUM"    	,SC6->C6_NUM	 , Nil })
			aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
			aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
			aAdd( _aItemPV , { "C6_UNSVEN"  ,SC6->C6_UNSVEN  , Nil }) // Quantidade Vendida 2 un
			aAdd( _aItemPV , { "C6_QTDVEN"  ,SC6->C6_QTDVEN  , Nil }) // Quantidade Vendida
			aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
			aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
			aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
			aAdd( _aItemPV , { "C6_LOJA"   	,SC6->C6_LOJA	 , Nil })
			aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
			aAdd( _aItemPV , { "C6_VALOR"   ,SC6->C6_VALOR   , Nil }) // valor total do item
			aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
			aAdd( _aItemPV , { "C6_TES"    	,SC6->C6_TES	 , Nil })
			aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
			aAdd( _aItemPV , { "C6_CF"     	,SC6->C6_CF		 , Nil })
			aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
			aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
			aAdd( _aItemPV , { "C6_PEDCLI" 	,SC6->C6_PEDCLI	 , Nil })
			aAdd( _aItemPV , { "C6_I_BLPRC"	,SC6->C6_I_BLPRC , Nil })

			aAdd( _aItensPV ,_aItemPV )

			SC6->( DBSkip() )
		EndDo

		// ESTORNO do pedido de Carregamento Gerado de Pallet
		lMsErroAuto:=.F.
		_cMensagem :='Estornou o Pedido Gerado de Pallet'+If(_lPedTrocaNF," (Troca NF)","")//Só aparece essa mensagem se o lMsErroAuto = .F.
		_cCliente  :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )

		//dd( _aLog     , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog1Aux , {.T.,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_NUM          ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )//Coloco o log antes pq depois tá deletado

		MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 5 )// ESTORNO do pedido de Carregamento Gerado de Pallet

		If lMsErroAuto
			_cMensagem:="Erro: ["+AllTrim(MostraErro())+"]"
			_aLog1Aux[Len(_aLog1Aux),1]:=.F.
			_aLog1Aux[Len(_aLog1Aux),3]:='Erro ao Estornar o Pedido Gerado de Pallet'+If(_lPedTrocaNF," (Troca NF)","")+", "+_cMensagem

			_lDeuErro:=.T.//Se der algum Erro
			Loop
		Else
			SC5->(DBSetOrder(1))
			If SC5->( DBSeek( xFilial("SC5") + _cPedGerou ) )//Pedido que gerou o Pallet
				SC5->(RecLock("SC5",.F.))
				SC5->C5_I_NPALE := ""
				SC5->C5_I_PEDPA := ""
				SC5->C5_I_PEDGE := ""
				SC5->(MSUnLock())
			EndIf
		EndIf
		// ESTORNO do pedido de Carregamento Gerado de Pallet
	EndIf//_lAchouCarga .And. _lPedTrocaNF
Next

For _nLog := 1 TO Len(_aLog2Aux)
	aAdd( _aLog , _aLog2Aux[_nLog] )
Next

For _nLog := 1 TO Len(_aLog1Aux)
	aAdd( _aLog , _aLog1Aux[_nLog] )
Next

Return .T.

/*
===============================================================================================================================
Programa--------: AcertaCarga(_aCargaAcerta)
Autor-----------: Alex Wallauer
Data da Criacao-: 18/08/2016
Descrição-------: Acerta a Capa das Cargas
Parametros------: _aCargaAcerta: Lista dos pedidos
Retorno---------: Lógico (.T.) 
===============================================================================================================================
*/
Static Function AcertaCarga(_aCargaAcerta)

Local _nTotPeso :=0,_nCa
Local _nTotValor:=0

ProcRegua(Len(_aCargaAcerta))

SC6->( DBSetOrder(1) )
DAK->( DBSetOrder(1) )
DAI->( DBSetOrder(1) )

For _nCa := 1 TO Len(_aCargaAcerta)
	IncProc("Acertando Carga: "+_aCargaAcerta[_nCa])

	If DAK->(DBSeek(_aCargaAcerta[_nCa])) .AND.;
			DAI->(DBSeek(DAK->DAK_FILIAL+DAK->DAK_COD))
		_nTotPeso :=0
		_nTotValor:=0

		While DAI->( !Eof() ) .And. DAI->DAI_FILIAL+DAI->DAI_COD == DAK->DAK_FILIAL+DAK->DAK_COD
			_nTotPeso += DAI->DAI_PESO
			SC6->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_PEDIDO ) )
			While SC6->( !Eof() ) .And. SC6->C6_FILIAL+SC6->C6_NUM == DAI->DAI_FILIAL+DAI->DAI_PEDIDO
				_nTotValor += SC6->C6_VALOR
				SC6->( DBSkip() )
			EndDo
			DAI->( DBSkip() )
		EndDo

		DAK->(RecLock("DAK",.F.))
		DAK->DAK_PESO  := _nTotPeso
		DAK->DAK_VALOR := _nTotValor
		DAK->(MSUnLock())
	EndIf
Next

Return .T.

/*
===============================================================================================================================
Programa--------: Ver_SC9(cChave)
Autor-----------: Alex Wallauer
Data da Criacao-: 30/08/2016
Descrição-------: Verefica se no SC9 esta tudo OK
Parametros------: cChave: Filia + Pedido
Retorno---------: Lógico (.F.) Se tudo OK (.T.) Se deu erro
===============================================================================================================================
*/
Static Function Ver_SC9(cChave)

Local _lErroSC9:=.F.//Não Tem erro

SC9->( DBSetOrder(1) )
If !SC9->( DBSeek( cChave ) )
	_lErroSC9:=.T.
EndIf

While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO) == cChave
	If (lBloqEstoque:=!Empty(SC9->C9_BLEST)) .Or. !Empty(SC9->C9_BLCRED)
		lBloqCredito:=!Empty(SC9->C9_BLCRED)
		_lErroSC9:=.T.//Tem erro
		Exit
	EndIf
	SC9->( DBSkip() )
EndDo

Return _lErroSC9

/*
===============================================================================================================================
Programa--------: VoltaPedFaturamento()
Autor-----------: Alex Wallauer
Data da Criacao-: 26/09/2016
Descrição-------: Verefica se no SC9 esta tudo OK ou tenta liberar o Pedido
Parametros------: _aPeds_Fat: { SC5->(RECNO()),,SC5->C5_I_FLFNC+" "+SC5->C5_I_PDPR,SC5->C5_I_FILFT+" "+SC5->C5_I_PDFT}
Retorno---------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
Static Function VoltaPedFaturamento(_aPeds_Fat)

Local _lOK:=.T.//Não Tem erro
Local _lPedPallat,_dDtEnt,_Ped,_cLocal,_cCliente
Local _aCabPV   :={}
Local _aItemPV  :={}
Local _aItensPV :={}
Local _aGuardaLocal:={}

For _Ped := 1 TO Len(_aPeds_Fat)
	SC5->( DBGoTo( _aPeds_Fat[_Ped,1] ))//Recno do Pedido DE FATURAMENTO originado da filial de carregamento

	IncProc("Lendo Pedido: "+SC5->C5_NUM)

	_lPedPallat:=(SC5->C5_I_PEDPA == "S" .And. SC5->C5_I_PEDGE # "S")
	// Limpa a carga do SC9 para nao dar mensagem de erro padrao no estorno da liberacao
	SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
	While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO) == SC5->C5_FILIAL + SC5->C5_NUM
		SC9->( RecLock('SC9',.F.) )
		SC9->C9_CARGA:=""
		SC9->C9_SEQCAR:=""
		SC9->C9_SEQENT:=""
		SC9->( MSUnLock() )
		SC9->( DBSkip() )
	EndDo

	_aCabPV   :={}
	_aItemPV  :={}
	_aItensPV :={}
	_dDtEnt	  :=If(SC5->C5_I_DTENT < DATE(),DATE(),SC5->C5_I_DTENT)//Para nao travar a alteracao do Pedido de Pallet

	// Monta o cabeçalho do pedido
	aAdd( _aCabPV, { "C5_FILIAL"	,SC5->C5_FILIAL  , Nil})//filial
	aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM	 , Nil})
	aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil})//Tipo de pedido
	aAdd( _aCabPV, { "C5_I_OPER"	,SC5->C5_I_OPER  , Nil})//Tipo da operacao
	aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL})//Codigo do cliente
	aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT	 , Nil})
	aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL})//Loja para entrada
	aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL})//Loja do cliente
	aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL})//Data de emissao
	aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP	 , Nil})
	aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL})//Codigo da condicao de pagamanto*
	aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1	 , Nil})
	aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil})//Moeda
	aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD	 , Nil})
	aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL})//Liberacao Total
	aAdd( _aCabPV, { "C5_TIPLIB"  	,SC5->C5_TIPLIB  , Nil})//Tipo de Liberacao
	aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL})//Tipo do Cliente
	aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL})//Numero que originou a pedido de palete
	aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL})//Pedido Refere a um pedido de Pallet
	aAdd( _aCabPV, { "C5_I_DTENT"	,_dDtEnt         , Nil})//Dt de Entrega
	aAdd( _aCabPV, { "C5_I_TRCNF"   ,SC5->C5_I_TRCNF , Nil})
	aAdd( _aCabPV, { "C5_I_BLPRC"   ,SC5->C5_I_BLPRC , Nil})
	aAdd( _aCabPV, { "C5_I_FILFT"   ,SC5->C5_I_FILFT , Nil})
	aAdd( _aCabPV, { "C5_I_FLFNC"   ,SC5->C5_I_FLFNC , Nil})

	// Monta o item do pedido
	SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
	_cLocal  :=SC6->C6_LOCAL

	While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
		_aItemPV:={}

		aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
		aAdd( _aItemPV , { "C6_NUM"    	,SC6->C6_NUM	 , Nil })
		aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
		aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
		aAdd( _aItemPV , { "C6_UNSVEN"  ,SC6->C6_UNSVEN  , Nil }) // Quantidade Vendida 2 un
		aAdd( _aItemPV , { "C6_QTDVEN"  ,SC6->C6_QTDVEN  , Nil }) // Quantidade Vendida
		aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
		aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
		aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
		aAdd( _aItemPV , { "C6_LOJA"   	,SC6->C6_LOJA	 , Nil })
		aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
		aAdd( _aItemPV , { "C6_VALOR"   ,SC6->C6_VALOR   , Nil }) // valor total do item
		aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
		aAdd( _aItemPV , { "C6_TES"    	,SC6->C6_TES	 , Nil })
		aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
		aAdd( _aItemPV , { "C6_CF"     	,SC6->C6_CF		 , Nil })
		aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
		aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
		aAdd( _aItemPV , { "C6_PEDCLI" 	,SC6->C6_PEDCLI	 , Nil })
		aAdd( _aItemPV , { "C6_I_BLPRC"	,SC6->C6_I_BLPRC , Nil })

		aAdd( _aItensPV ,_aItemPV )

		SC6->( DBSkip() )
	EndDo

	// ALTERAÇÃO do pedido de Faturamento para liberar o estoque
	lMsErroAuto:=.F.

	MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )// ALTERAÇÃO do pedido de Faturamento para liberar o estoque

	SC5->( DBGoTo( _aPeds_Fat[_Ped,1] ))//Recno do Pedido DA FATURAMENTO
	_cCliente   :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )

	lErroSC9:=.F.
	SC9->( DBSetOrder(1) )
	If lMsErroAuto .Or. ( lErroSC9:=SC9->( DBSeek( SC5->C5_FILIAL+SC5->C5_NUM ) ))//Se liberou o estoque nao pode achar no SC9, portanto se char é um erro
		If lErroSC9
			_cMensagem:="Erro ao Estornar a liberação do Pedido de Faturamento"+If(_lPedPallat," de Pallet","")+" (Troca NF), ainda tem dados de liberacao (SC9)."
		Else
			_cMensagem:="Erro: ["+AllTrim(MostraErro())+"]"
			_cMensagem:='Erro ao Estornar a liberação do Pedido de Faturamento'+If(_lPedPallat," de Pallet","")+" (Troca NF), "+_cMensagem
		EndIf

		//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.F.,""          ,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_I_PDPR       ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )

		_lDeuErro:=.T.//Se der algum Erro
	Else
		// Array que controla os Pedidos de Origem lincados com o Pedidos gerados de Carregamento
		//1-Filial de Origem,2-Pedido de Origem,3-NIL , 4-Filial Gerada ,5-Pedido Gerado  ,6-Cliente ,7-Armazem, 8-Coluna de ordenacao para deixar os Pallets em primeiro
		aAdd(aLink_POV_PON, { SC5->C5_I_FILFT, SC5->C5_I_PDFT   ,      , SC5->C5_I_FLFNC ,  SC5->C5_I_PDPR , _cCliente, _cLocal , If(_lPedPallat,"A-PV Pallet","B-PV") } )

		_cMensagem:='Estornou a liberação do Pedido de Faturamento'+If(_lPedPallat," de Pallet","")+" (Troca NF)"

		//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.T.,""          ,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_I_PDPR       ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )

	EndIf
	// ALTERAÇÃO do pedido de Faturamento para liberar o estoque (Troca NF)
Next

// TRANSFERENCIA do pedido de Faturamento para filial de carregamento
ProcRegua(Len(aLink_POV_PON))

aLink_POV_PON:= aSort(aLink_POV_PON,,,{|x,y| x[8] < y[8] })//Ordenacao para deixar os Pallets em primeiro

For _Ped := 1 TO Len(aLink_POV_PON)// 1-Filial de Origem, 2-Pedido de Origem, 3-NIL   ,4-Filial Gerada    , 5-Pedido Gerado ,6-cCliente,7-Armazem
	IncProc("Voltando Pedido: "+aLink_POV_PON[_Ped,2])

	SC5->( DBSetOrder(1) )//Os DBSetOrder estao dentro do For por causa do MSExec Auto ()
	SC6->( DBSetOrder(1) )
	SC9->( DBSetOrder(1) )

	If !SC5->( DBSeek( aLink_POV_PON[_Ped,1]+aLink_POV_PON[_Ped,2] ) )//Posiciona no Pedido de Faturamento que era o velho de Carregamento
		_cMensagem:='Pedido de Faturamento nao Encontrado'
		//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente'            ,'Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.F.,""          ,_cMensagem    ,aLink_POV_PON[_Ped,6],aLink_POV_PON[_Ped,4],aLink_POV_PON[_Ped,5],aLink_POV_PON[_Ped,1],aLink_POV_PON[_Ped,2]} )
		_lDeuErro:=.T.//Se der algum Erro
		Loop
	EndIf

	_lPedPallat :=(SC5->C5_I_PEDPA == "S" .And. SC5->C5_I_PEDGE # "S")

	If SC9->( DBSeek( aLink_POV_PON[_Ped,1]+aLink_POV_PON[_Ped,2] ) )   //Posiciona no SC9 do Pedido de Faturamento que era o velho de Carregamento
		_cMensagem:='Pedido de Faturamento '+If(_lPedPallat," de Pallet","")+' ainda esta liberado (SC9)'
		//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente'            ,'Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.F.,""          ,_cMensagem    ,aLink_POV_PON[_Ped,6],aLink_POV_PON[_Ped,4],aLink_POV_PON[_Ped,5],aLink_POV_PON[_Ped,1],aLink_POV_PON[_Ped,2]} )
		_lDeuErro:=.T.//Se der algum Erro
		Loop
	EndIf

	//DESVINCULANDO O CARREGAMENTO
	_aGuardaLocal:={}
	If !SC5->( DBSeek( aLink_POV_PON[_Ped,4]+aLink_POV_PON[_Ped,5] ) )//Posiciona no Pedido de Carregamento Gerado
		_cMensagem:='Pedido de Carregamento nao Encontrado, mas não invalida o Retorno do Pedido de Faturamento'
		//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente'            ,'Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.F.,""          ,_cMensagem    ,aLink_POV_PON[_Ped,6],aLink_POV_PON[_Ped,4],aLink_POV_PON[_Ped,5],aLink_POV_PON[_Ped,1],aLink_POV_PON[_Ped,2]} )
	Else
		SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
		While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
			aAdd( _aGuardaLocal , { SC6->C6_ITEM,SC6->C6_LOCAL,SC6->C6_TES } )
			SC6->( DBSkip() )
		EndDo

		SC5->( RecLock( 'SC5' , .F. ) )
		SC5->C5_I_TRCNF:= "N"// Nao vai ser mais troca nota
		SC5->C5_I_FILFT:= "" // Limpa a filial
		SC5->C5_I_FLFNC:= "" // Limpa a filial
		SC5->C5_I_PDFT := "" // Limpa Pedido de Origem (codigo é o mesmo só que na filial de faturamento agora)
		SC5->C5_I_PDPR := "" // Limpa Código do Pedido novo de Carregamento
		SC5->( MSUnLock() )
	EndIf
	//DESVINCULANDO O CARREGAMENTO

	//EXCLUIR PEDIDO DE PALLET
	SC5->( DBSeek( aLink_POV_PON[_Ped,1]+aLink_POV_PON[_Ped,2] ) )//Posiciona DE NOVO no Pedido de Faturamento de Pallet de novo que era o velho de Carregamento
	If _lPedPallat// Se For de Pallet exclui
		_aCabPV   :={}
		_aItemPV  :={}
		_aItensPV :={}
		_dDtEnt	 := If(SC5->C5_I_DTENT < DATE(),DATE(),SC5->C5_I_DTENT)//Para nao travar a exclusao do Pedido de Pallet
		_cPedGerou:= SC5->C5_FILIAL+SC5->C5_I_NPALE

		// Monta o cabeçalho do pedido de pallet
		aAdd( _aCabPV, { "C5_FILIAL"  	,SC5->C5_FILIAL  , Nil})//filial
		aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM	 , Nil})
		aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil})//Tipo de pedido
		aAdd( _aCabPV, { "C5_I_OPER"	    ,SC5->C5_I_OPER  , Nil})//Tipo da operacao
		aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL})//Codigo do cliente
		aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT	 , Nil})
		aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL})//Loja para entrada
		aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL})//Loja do cliente
		aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL})//Data de emissao
		aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP	 , Nil})
		aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL})//Codigo da condicao de pagamanto*
		aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1	 , Nil})
		aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil})//Moeda
		aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD	 , Nil})
		aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL})//Liberacao Total
		aAdd( _aCabPV, { "C5_TIPLIB"  	,SC5->C5_TIPLIB  , Nil})//Tipo de Liberacao
		aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL})//Tipo do Cliente
		aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL})//Numero que originou a pedido de palete
		aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL})//Pedido Refere a um pedido de Pallet
		aAdd( _aCabPV, { "C5_I_DTENT"	,_dDtEnt         , Nil})//Dt de Entrega
		aAdd( _aCabPV, { "C5_I_TRCNF"    ,SC5->C5_I_TRCNF , Nil})
		aAdd( _aCabPV, { "C5_I_BLPRC"    ,SC5->C5_I_BLPRC , Nil})
		aAdd( _aCabPV, { "C5_I_FILFT"    ,SC5->C5_I_FILFT , Nil})
		aAdd( _aCabPV, { "C5_I_FLFNC"    ,SC5->C5_I_FLFNC , Nil})

		// Monta o item do pedido de pallet
		SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

		While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
			_aItemPV:={}

			aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
			aAdd( _aItemPV , { "C6_NUM"     ,SC6->C6_NUM	   , Nil })
			aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
			aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
			aAdd( _aItemPV , { "C6_UNSVEN"  ,SC6->C6_UNSVEN  , Nil }) // Quantidade Vendida 2 un
			aAdd( _aItemPV , { "C6_QTDVEN"  ,SC6->C6_QTDVEN  , Nil }) // Quantidade Vendida
			aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
			aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
			aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
			aAdd( _aItemPV , { "C6_LOJA"    ,SC6->C6_LOJA	   , Nil })
			aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
			aAdd( _aItemPV , { "C6_VALOR"   ,SC6->C6_VALOR   , Nil }) // valor total do item
			aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
			aAdd( _aItemPV , { "C6_TES"     ,SC6->C6_TES	   , Nil })
			aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
			aAdd( _aItemPV , { "C6_CF"      ,SC6->C6_CF	   , Nil })
			aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
			aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
			aAdd( _aItemPV , { "C6_PEDCLI"  ,SC6->C6_PEDCLI  , Nil })
			aAdd( _aItemPV , { "C6_I_BLPRC" ,SC6->C6_I_BLPRC , Nil })

			aAdd( _aItensPV ,_aItemPV )

			SC6->( DBSkip() )
		EndDo

		// ESTORNO do pedido de Faturamento Gerado de Pallet
		lMsErroAuto:=.F.
		_cMensagem :='Estornou o Pedido Gerado de Pallet (Troca NF)'//Só aparece essa mensagem se o lMsErroAuto = .F.
		_cCliente  :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )

		//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.T.,""          ,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_NUM          ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )

		MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 5 )// ESTORNO do pedido de Faturamento Gerado de Pallet

		If lMsErroAuto
			_cMensagem:="Erro: ["+AllTrim(MostraErro())+"]"
			_aLog[Len(_aLog),1]:=.F.
			_aLog[Len(_aLog),3]:="Erro ao Estornar o Pedido Gerado de Pallet (Troca NF), "+_cMensagem

			_lDeuErro:=.T.//Se der algum Erro
			Loop
		Else
			SC5->(DBSetOrder(1))
			If SC5->( DBSeek( _cPedGerou ) )//Pedido que gerou o Pallet
				SC5->(RecLock("SC5",.F.))
				SC5->C5_I_NPALE := ""
				SC5->C5_I_PEDPA := ""
				SC5->C5_I_PEDGE := ""
				SC5->(MSUnLock())
			EndIf
		EndIf
		Loop
	Else// Se não  For de Pallet desvincula somente
		SC5->( RecLock( 'SC5' , .F. ) )
		SC5->C5_I_TRCNF:= "N"// Nao vai ser mais troca nota
		SC5->C5_I_FILFT:= "" // Limpa a filial
		SC5->C5_I_FLFNC:= "" // Limpa a filial
		SC5->C5_I_PDFT := "" // Limpa Pedido de Origem (codigo é o mesmo só que na filial de faturamento agora)
		SC5->C5_I_PDPR := "" // Limpa Código do Pedido novo de Carregamento
		SC5->C5_I_CARGA:= "" // Limpa o numero da Carga de Origem pq senão não dá para fazer montagem de carga dele
		SC5->( MSUnLock() )
		Loop
	EndIf//If _lPedPallat
	//EXCLUIR PEDIDO DE PALLET
Next

Return _lOK

/*
===============================================================================================================================
Programa--------: Exclui_NF()
Autor-----------: Alex Wallauer
Data da Criacao-: 26/09/2016
Descrição-------: Verefica se no SC9 esta tudo OK ou tenta liberar o Pedido
Parametros------: _aNF_Fat: lista de pedidos do DAI
Retorno---------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
Static Function Exclui_NF(_aNF_Fat)

Local _lOK:=.T.//Não Tem erro
Local _Ped
Local _nRecSM0:=SM0->(RECNO())
Local _cFornT  :=""
Local _cLojaT  :=""
Local _lRet:=.T.

DAI->( DBGoTo( _aNF_Fat[1,1] ))//Recno do DAI da carga de carregamento
_cFilCarregamento:=DAI->DAI_FILIAL
SM0->( DBSetOrder(1) )
SM0->(DBGoTop())
While SM0->(!Eof())
	If _cFilCarregamento == AllTrim(SM0->M0_CODFIL)
		_cCNPJ:=SM0->M0_CGC
		Exit
	EndIf
	SM0->(DBSkip())
EndDo
SM0->(DBGoTo(_nRecSM0))

SA2->( DBSetOrder(3) )
If SA2->(DBSeek(xFilial("SA2")+_cCNPJ))
	_cFornT  :=SA2->A2_COD
	_cLojaT  :=SA2->A2_LOJA
EndIf
SA2->( DBSetOrder(1) )
_cCliente:=_cFornT+" / "+_cLojaT+" / "+AllTrim( Posicione("SA2",1,xFilial("SA2")+_cFornT+_cLojaT,"A2_NREDUZ") )

For _Ped := 1 TO Len(_aNF_Fat)
	DAI->( DBGoTo( _aNF_Fat[_Ped,1] ))//Recno do DAI da carga de carregamento

	_cNotaT  :=DAI->DAI_NFISCA
	_cSerieT :=DAI->DAI_SERIE

	IncProc("Exclulindo NF: "+_cNotaT+" "+_cSerieT)

	SF1->(DBSetOrder(1))
	SD1->(DBSetOrder(1))
	If !Empty(_cFornT) .And. SF1->(DBSeek(xFilial("SF1")+_cNotaT+_cSerieT+_cFornT+_cLojaT ))
		If Empty(SF1->F1_STATUS)
			lNFClassificada := .F.
		Else
			lNFClassificada := .T.
		EndIf
		_cMensagem :=""

		_lRet:=U_MT100PedAlt( _aNF_Fat[_Ped,5] )//Estorna a liberação do pedido de Faturamento

		If !_lRet
			//_lDeuErro :=.T. //Não vai devolver erro pq isso pode ser feito manualmente
			_cMensagem:="Nao foi possivel Estornar a liberação do Pedido de Faturamento da NF"+If(lNFClassificada," Classificada"," ")+": "+_cNotaT+" "+AllTrim(_cSerieT)+". Tente excluir manualmente, "+_cMensagem
		Else
			SD1->(DBSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))
			aItens:={}
			While SD1->(!Eof()).AND. SD1->D1_FILIAL == xFilial("SD1") .And. SD1->D1_DOC    == SF1->F1_DOC    .And. SD1->D1_SERIE  == SF1->F1_SERIE  .And.               SD1->D1_FORNECE== SF1->F1_FORNECE.And.               SD1->D1_LOJA   == SF1->F1_LOJA
				aItem:={}
				aAdd(aItem,{"D1_DOC"    ,SD1->D1_DOC    ,NIL})
				aAdd(aItem,{"D1_SERIE"  ,SD1->D1_SERIE  ,NIL})
				aAdd(aItem,{"D1_FORNECE",SD1->D1_FORNECE,NIL})
				aAdd(aItem,{"D1_LOJA"   ,SD1->D1_LOJA   ,NIL})

				aAdd(aItens,ACLONE(aItem))

				SD1->(DBSkip())
			EndDo

			aCab := {}
			aAdd(aCab,{"F1_DOC"    ,SF1->F1_DOC    ,NIL})   // NUMERO DA NOTA
			aAdd(aCab,{"F1_SERIE"  ,SF1->F1_SERIE  ,NIL})   // SERIE DA NOTA
			aAdd(aCab,{"F1_FORNECE",SF1->F1_FORNECE,NIL})   // FORNECEDOR
			aAdd(aCab,{"F1_LOJA"   ,SF1->F1_LOJA   ,NIL})   // LOJA DO FORNECEDOR
			aAdd(aCab,{"F1_TIPO"   ,SF1->F1_TIPO   ,NIL})   // TIPO DA NF

			lMsErroAuto:=.F.

			If lNFClassificada
				MSExecAuto({|x,y,z| MATA103(x,y,z)},aCab,aItens,20)//Estorna a NF Classificada
			Else
				MSExecAuto({|x,y,z| MATA140(x,y,z)},aCab,aItens,5)//Estorna a NF não Classificada
			EndIf

			If lMSErroAuto .Or. SF1->(DBSeek(xFilial("SF1")+_cNotaT+_cSerieT+_cFornT+_cLojaT ))
				If lMSErroAuto
					_cMensagem:="Erro: ["+AllTrim(MostraErro())+"]"
				EndIf
				//_lDeuErro :=.T. //Não vai devolver erro pq isso pode ser feito manualmente
				_cMensagem:="Nao foi possivel Estornar a NF"+If(lNFClassificada," Classificada"," ")+": "+_cNotaT+" "+AllTrim(_cSerieT)+". Tente excluir manualmente, "+_cMensagem
			Else
				_cMensagem:="NF: "+_cNotaT+" "+AllTrim(_cSerieT)+" excluida com sucesso"
			EndIf
		EndIf
	Else
		//_lDeuErro :=.T. //Não vai devolver erro pq se não achou é pq já excluiram
		_cMensagem:="Nao foi possivel Encontrar a NF: "+_cNotaT+" "+_cSerieT
	EndIf

	SC5->( DBGoTo( _aNF_Fat[_Ped,2] ))//Recno do Pedido de Carregamento

	//dd( _aLog ,{" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
	aAdd( _aLog ,{.T.,DAI->DAI_COD,_cMensagem    ,_cCliente,SC5->C5_I_FLFNC      ,SC5->C5_I_PDPR       ,SC5->C5_I_FILFT     ,SC5->C5_I_PDFT} )
Next

Return _lOK

/*
===============================================================================================================================
Programa--------: OpcExclusao
Autor-----------: Alex Wallauer
Data da Criacao-: 04/11/2016
Descrição-------: Decide opcoes de exclusão
Parametros------: _cCargaExclui: No. da Carga , lCarga_Digitada: Se .T. foi chamado da opção do aRotina "Corrgir Exclusao"
Retorno---------: nEscolha: 1 ou 2 ou 0
===============================================================================================================================
*/
Static Function OpcExclusao(_cCargaExclui,lCarga_Digitada)

Local oDlgEx,_nEscolha:=0
Local _nLinha := 08
Local _nPula  := 12
Local _nCol   := 180,_oMemo,_oMem2
Local _c1Pergunta:="Notas de saida já foram excluídas com sucesso!"
Local _c2Pergunta:="Deseja excluir a Carga e as NFEs de transferencia abaixo?"
Local _c3Pergunta:="Ou Manter as NFEs de transferencia e voltar Pedidos de"
Local _c4Pergunta:="Faturamento para Filial de Carregamento?"
Local _cMemo:=_cMemoAux:="Carga: "+_cCargaExclui+CRLF+_cNFEs
Local _cMem2:=_cMem2Aux:="Pedido(s) de Faturamento: "+CRLF+_cPVFats
Local _c1Say:="Excluir Carga e NFEs        "
Local _c2Say:="Manter Carga e NFEs         "
Local _c3Say:="Manter NFEs e Voltar Pedidos"

If _lAchouCarga .And. _lAchouSC9 .And. lCarga_Digitada //Retesta por garantia
	_cProblema:="A carga "+_cCargaExclui+" ainda existe no sistema."
	_cSolucao :="Para usar essa opção a carga não pode existir no sistema. Exclua a carga manualmente."
	xMagHelpFis("Atenção (OM521BRW) 006",_cProblema,_cSolucao)
	Return 0
EndIf

While .T.
	_nEscolha:=0
	_nLinha  :=8

	DEFINE MSDIALOG oDlgEx TITLE "Opções de Exclusão de NF (OM521BRW)" From 000,000 To 220,555 Pixel Style DS_MODALFRAME

	If lCarga_Digitada
		_c2Pergunta:="Deseja Regerar a Carga ou Excluir NFEs de transferencia abaixo?"
		_c1Say:="Excluir NFEs"
		_c2Say:="Regerar Carga"
	Else
		oDlgEx:LESCCLOSE := .F.//Comando para impedir o uso da tecla ESC para fechar a janela
	EndIf

	@_nLinha,005 Say Upper(_c1Pergunta) PIXEL
	_nLinha+=_nPula
	@_nLinha,005 Say _c2Pergunta PIXEL
	_nLinha+=_nPula
	@_nLinha,005 Say _c3Pergunta PIXEL
	_nLinha+=_nPula
	@_nLinha,005 Say _c4Pergunta PIXEL
	_nLinha+=_nPula
	@_nLinha,005 GET _oMemo VAR _cMemo MEMO HSCROLL SIZE 60,50 PIXEL
	@_nLinha,080 GET _oMem2 VAR _cMem2 MEMO HSCROLL SIZE 75,50 PIXEL

	_nLinha := 10

	@_nLinha,_nCol Button _c1Say Size 80,15 Action (_nEscolha:=1,oDlgEx:End()) PIXEL WHEN (_cMemo:=_cMemoAux,_oMemo:Refresh(),.T.)
	_nLinha+=_nPula+7
	@_nLinha,_nCol Button _c2Say Size 80,15 Action (_nEscolha:=2,oDlgEx:End()) PIXEL WHEN (_cMem2:=_cMem2Aux,_oMem2:Refresh(),.T.)
	_nLinha+=_nPula+7
	@_nLinha,_nCol Button _c3Say Size 80,15 Action (_nEscolha:=3,oDlgEx:End()) PIXEL
	_nLinha+=_nPula+7
	If lCarga_Digitada
		@ _nLinha,_nCol Button "CANCELA"  Size 80,15 Action (_nEscolha:=0,oDlgEx:End()) PIXEL
	EndIf

	ACTIVATE MSDIALOG oDlgEx CENTERED

	If _nEscolha # 0

		If(DAK->( DBSeek( xFilial("DAK")+_cCargaExclui+"01" ) ) .AND.;
				DAI->( DBSeek( xFilial("DAK")+_cCargaExclui+"01" ) )) .And. _lAchouSC9//Retesta por garantia

			_cProblema:="A carga "+_cCargaExclui+" ainda existe no sistema."
			_cSolucao :="Para usar essas opções a carga não pode existir no sistema. Exclua a carga manualmente."
			xMagHelpFis("Atenção (OM521BRW) 007",_cProblema,_cSolucao)

			Return 0
		EndIf

		If _nEscolha = 3 .And. !MSGYesNO("Essa ação não tem como desfazer, Tem certeza que deseja voltar Pedidos de "+;
				"Faturamento para Filial de Carregamento?","Atenção (OM521BRW) 008")
			Loop
		EndIf
	EndIf
	Exit
EndDo

Return _nEscolha

/*
===============================================================================================================================
Programa--------: M520DelCarga()
Autor-----------: Alex Wallauer
Data da Criacao-: 21/03/2017
Descrição-------: Deleta a carga
Parametros------: _cFilCarga: Filial , _cCargaExclui: Carga Posicionada ,_cSeqCarga: Seq da Carga
Retorno---------: Lógico (.T.)
===============================================================================================================================*/
Static Function M520DelCarga(_cFilCarga,_cCargaExclui,_cSeqCarga)

DAK->( DBSetOrder(1) ) //DAK_FILIAL+DAK_COD+DAK_SEQCAR
If DAK->( DBSeek( _cFilCarga+_cCargaExclui+_cSeqCarga ) ) //Tem casos que os estorno deleta a carga e tem casos que nao POR CAUSA DE ALGUM ERRO NA EXLCUSO PADRAO
	DAI->( DBSetOrder(1) )
	If !DAI->( DBSeek( _cFilCarga+_cCargaExclui+_cSeqCarga ) )
		DAK->(RecLock("DAK",.F.))
		DAK->(DBDELETE())
		DAK->(MSUnLock())
		_cMensagem:='Carga sem Pedidos (DAI). Capa da carga (DAK) apagada com sucesso ('+_cFilCarga+' '+_cCargaExclui+' '+_cSeqCarga+')'
		//aAdd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
		aAdd( _aLog , {.T.,DAI->DAI_COD,_cMensagem    ,""       ,""                   ,""                   ,""                  ,""            } )
	Else//Se chegou nesse ponto é pq não tem nenhuma nota com esse numero da carga isso não quer dizer que a nota não esteja vinculada para outra carga
		SC9->( DBSetOrder(1) )//C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED
		While DAI->(!Eof()) .And. DAI->( DAI_FILIAL+DAI_COD+DAI_SEQCAR ) == _cFilCarga+_cCargaExclui+_cSeqCarga//Tem casos que os estorno deleta a carga e tem casos que nao POR CAUSA DE ALGUM ERRO NA EXLCUSO PADRAO
			If !SC9->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_PEDIDO ) )
				DAI->(RecLock("DAI",.F.))
				DAI->(DBDELETE())
				DAI->(MSUnLock())
				_cMensagem:='Pedido sem reserva de estoque (SC9) foi apagado da carga (DAI) com sucesso: '+DAI->DAI_FILIAL +" "+ DAI->DAI_PEDIDO
				//aAdd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
				aAdd( _aLog , {.T.,DAI->DAI_COD,_cMensagem    ,""       ,DAI->DAI_FILIAL      , DAI->DAI_PEDIDO     ,""                  ,""            } )
			Else
				_cMensagem:='Pedido com reserva de estoque (SC9) naõ foi apagado da carga (DAI): '+DAI->DAI_FILIAL +" "+ DAI->DAI_PEDIDO
				aAdd( _aLog , {.F.,DAI->DAI_COD,_cMensagem    ,""       ,DAI->DAI_FILIAL      , DAI->DAI_PEDIDO     ,""                  ,""            } )
			EndIf
			DAI->(DBSkip())
		EndDo

		If DAI->( DBSeek( _cFilCarga+_cCargaExclui+_cSeqCarga ) )// SE TEM DAI AINDA *********************************//
			If DAK->DAK_FEZNF = "1"
				DAK->(RecLock("DAK",.F.))
				DAK->DAK_FEZNF:="2"
				DAK->(MSUnLock())
				_cMensagem:='Carga alterada para "não faturada" por não ter notas geradas'
				//aAdd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
				aAdd( _aLog , {.T.,DAI->DAI_COD,_cMensagem    ,""       ,DAK->DAK_FILIAL      , ""                  ,""                  ,""            } )
			EndIf
			While DAI->(!Eof()) .And. DAI->( DAI_FILIAL+DAI_COD+DAI_SEQCAR ) == _cFilCarga+_cCargaExclui+_cSeqCarga//Tem casos que os estorno deleta a carga e tem casos que nao POR CAUSA DE ALGUM ERRO NA EXLCUSO PADRAO
				If !Empty(DAI->DAI_NFISCA)
					_cMensagem:='Nota do Pedido (DAI_NFISCA) limpa da carga com sucesso: '+DAI->DAI_NFISCA
					DAI->(RecLock("DAI",.F.))
					DAI->DAI_NFISCA:=""
					DAI->(MSUnLock())
					//aAdd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
					aAdd( _aLog , {.T.,DAI->DAI_COD,_cMensagem    ,""       ,DAI->DAI_FILIAL      , DAI->DAI_PEDIDO     ,""                  ,""            } )
				EndIf
				DAI->(DBSkip())
			EndDo
		Else//SE NÃO TEM MAIS DAI
			DAK->(RecLock("DAK",.F.))
			DAK->(DBDELETE())
			DAK->(MSUnLock())
			_cMensagem:='Carga sem Pedidos (DAI). Capa da carga (DAK) apagada com sucesso ('+_cFilCarga+' '+_cCargaExclui+' '+_cSeqCarga+')'
			//dd( _aLog , {" ",'Carga '    ,'Movimentacao','Cliente','Filial Carregamento','Pedido Carregamento','Filial Faturamento','Pedido Faturamento'} )
			aAdd( _aLog , {.T.,DAI->DAI_COD,_cMensagem    ,""       ,""                   ,""                   ,""                  ,""            } )
		EndIf
	EndIf
EndIf

Return .T.

/*
===============================================================================================================================
Programa--------: OM521TMS()
Autor-----------: Igor Melgaço
Data da Criacao-: 01/02/2024
Descrição-------: Integrações com o TMS para Cancelamento Dos Documentos Da Carga ou Cancelamento Da Carga
Parametros------: oProc: Objeto do processo que chama a função
                  cAliasSF2: Alias da SF2
                 _lScheduler: Lógico (.T.) Se For chamado pelo Scheduler (.F.) se For chamado pelo usuário
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================
*/
User Function OM521TMS(oProc,cAliasSF2,_lScheduler)

Local oWsdl
Local _cXML           := ""
Local _cLink          := ""
Local _cToken         := SuperGetMV('IT_TOKMUTE',.T.,"a78e0523d3794843855e8d95c2bff8d4")
Local _cEmpWebService := SuperGetMV('IT_EMPTMSM',.T.,"000005")
Local _lReturn        := .F.
Local cReplace:= ""
Local cErros:= ""
Local cAvisos := ""

Begin Sequence

	If ValType(_lScheduler) == Nil
		_lScheduler := .F.
	EndIf

	Pergunte("MTA521",.F.) // Para atualizar em memória os conteúdos das variáveis MV_PARXX selecionados com a tecla F12.

	If Type("_nRecno_DAK") = "N" .And. DAK->(Recno()) <> _nRecno_DAK
		DAK->(MsGoto(_nRecno_DAK))
	EndIf
	If DAK->DAK_I_TMS  <> "M"//Se não For integracao do TMS MultiEmbarcador não faz nada
		_lReturn:= .T.
		Break
	EndIf
	ZFM->(DBSetOrder(1))
	If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
		_cLink   := AllTrim(ZFM->ZFM_LINK01) //Cargas
	Else
		If ! _lScheduler
			MsgInfo("Empresa WebService para envio dos dados não localizada.","Atenção")
		Else
			u_itconout("[OM521TMS] Empresa WebService para envio dos dados não localizada.")
		EndIf

		_lReturn := .F.

		Break
	EndIf

	If Empty(AllTrim(_cLink))
		If ! _lScheduler
			MsgInfo("Empresa WebService para envio dos dados não possui link cadastrado!.","Atenção")
		Else
			u_itconout("[OM521TMS] Empresa WebService para envio dos dados não possui link cadastrado!.")
		EndIf

		_lReturn := .F.

		Break
	EndIf

	oWsdl := tWSDLManager():New() // Cria o objeto da WSDL.
	oWsdl:nTimeout := 60          // Timeout de xx segundos
	oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo

	oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da TMS.

	_cCarga    := DAK->DAK_COD

	_cMotivo   := "Carga cancelada no Protheus"
	_cUsuario  := UsrFullName(RetCodUsr())

	If DAK->DAK_I_TRNF = ' ' .Or. DAK->DAK_I_TRNF = 'N'
		// Se MV_PAR04 == 1 = Carteira = MV do Pergunte("MTA521")  ao teclar F12.
		_cProtIntC := AllTrim(DAK->DAK_I_RECR) //    Executa o solicitarCancelamentoDaCarga com o DAK_I_RECR
		// Senão
		//    Executa o solicitarCancelamentoDosDocumentosDaCarga com o DAK_I_RECR
		// Fim_Se

	ElseIf DAK->DAK_I_TRNF = 'C' .Or. DAK->DAK_I_TRNF = 'F'
		// If MV_PAR04 == 1 // Carteira = MV do Pergunte("MTA521")  ao teclar F12.
		_cProtIntC := AllTrim(DAK->DAK_I_PTMS) //    Executa o solicitarCancelamentoDaCarga com o DAK_I_PTMS e também com o DAK_I_RECR
		// Senão
		//    Executar o solicitarCancelamentoDosDocumentosDaCarga com o DAK_I_PTMS e também com o DAK_I_RECR
		// Fim_Se
	EndIf

	// Se DAK_I_PTMS estiver vazio, utilizar apenas o Protocolo DAK_I_RECR
	If Empty(_cProtIntC)
		_cProtIntC := AllTrim(DAK->DAK_I_RECR)
	EndIf

	If MV_PAR04 == 2 // Apto Faturar = MV do Pergunte("MTA521")  ao teclar F12.
		If ! _lScheduler
			U_ITMsg('Metodo chamado : "SolicitarCancelamentoDosDocumentosDaCarga". '+CRLF+'Tecla F12: MV_PAR04 = 2 = Apto Faturar.',"Atenção",,1)
		EndIf

		//_cProtIntC := AllTrim(DAK->DAK_I_RECR) // Manter a regra acima.
		oWsdl:SetOperation( "SolicitarCancelamentoDosDocumentosDaCarga") // Define qual operação será realizada.

		If oProc <> NIL
			oProc:cCaption := ("Cancelando os Documentos da Carga "+_cCarga+" no TMS...")
			ProcessMessages()
		EndIf

		_cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
		_cXML += '<soapenv:Header>'
		_cXML += '    <Token xmlns="Token">'+_cToken+'</Token>'
		_cXML += '</soapenv:Header>'
		_cXML += '   <soapenv:Body>'
		_cXML += '      <tem:SolicitarCancelamentoDosDocumentosDaCarga>'
		//_cXML += '         <!--Optional:-->'
		_cXML += '         <tem:protocoloIntegracaoCarga>'+_cProtIntC+'</tem:protocoloIntegracaoCarga>'
		//_cXML += '         <!--Optional:-->'
		_cXML += '         <tem:motivoDoCancelamento>"'+_cMotivo+'"</tem:motivoDoCancelamento>'
		//_cXML += '         <!--Optional:-->'
		_cXML += '         <tem:usuarioERPSolicitouCancelamento>"'+_cUsuario+'"</tem:usuarioERPSolicitouCancelamento>'
		_cXML += '      </tem:SolicitarCancelamentoDosDocumentosDaCarga>'
		_cXML += '   </soapenv:Body>'
		_cXML += '</soapenv:Envelope>'

		// Envia para o servidor
		_lOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da TMS.

		If _lOk
			_cResult := oWsdl:GetParsedResponse() // Pega o resultado de envio já no formato em string.
			oResult := XmlParser(oWsdl:GetSoapResponse(), cReplace, @cErros, @cAvisos)

			If oResult:_S_ENVELOPE:_S_BODY:_SolicitarCancelamentoDosDocumentosDaCargaRESPONSE:_SolicitarCancelamentoDosDocumentosDaCargaRESULT:_A_STATUS:TEXT == "false"
				_lReturn   := .F.
				_lOk       := .F.
				_cMensagem := oResult:_S_ENVELOPE:_S_BODY:_SolicitarCancelamentoDosDocumentosDaCargaRESPONSE:_SolicitarCancelamentoDosDocumentosDaCargaRESULT:_A_MENSAGEM:TEXT
			EndIf
		Else
			_lReturn := .F.
			_cResult := oWsdl:cError
			_cMensagem  := _cResult
		EndIf

		If _lOk
			_lReturn := OM521ENFPC(oProc,oWsdl,cAliasSF2)
		Else
			U_ITMsg('Falha no Cancelamento Dos Documentos Da Carga no TMS' + DAK->DAK_COD + CRLF +'Mensagem API TMS: ' + _cMensagem,"Atenção",,1)
		EndIf

	Else // MV_PAR04 == 1 // Carteira = MV do Pergunte("MTA521")  ao teclar F12.
		If ! _lScheduler
			U_ITMsg('Metodo chamado : "SolicitarCancelamentoDaCarga". '+CRLF+'Tecla F12: MV_PAR04 = 1 = Carteira.',"Atenção",,1)
		EndIf

		oWsdl:SetOperation( "SolicitarCancelamentoDaCarga") // Define qual operação será realizada.

		oProc:cCaption := ("Cancelando a Carga "+_cCarga+" ...")
		ProcessMessages()

		_cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
		_cXML += '<soapenv:Header>'
		_cXML += '    <Token xmlns="Token">'+_cToken+'</Token>'
		_cXML += '</soapenv:Header>'
		_cXML += '   <soapenv:Body>'
		_cXML += '      <tem:SolicitarCancelamentoDaCarga>'
		_cXML += '         <tem:protocoloIntegracaoCarga>'+_cProtIntC+'</tem:protocoloIntegracaoCarga>'
		_cXML += '      </tem:SolicitarCancelamentoDaCarga>'
		_cXML += '   </soapenv:Body>'
		_cXML += '</soapenv:Envelope>'

		// Envia para o servidor
		_lOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da TMS.

		If _lOk
			_cResult := oWsdl:GetParsedResponse() // Pega o resultado de envio já no formato em string.
			oResult  := XmlParser(oWsdl:GetSoapResponse(), cReplace, @cErros, @cAvisos)

			If oResult:_S_ENVELOPE:_S_BODY:_SolicitarCancelamentoDaCargaRESPONSE:_SolicitarCancelamentoDaCargaRESULT:_A_STATUS:TEXT == "false"
				_lReturn   := .F.
				_lOk       := .F.
				_cMensagem := oResult:_S_ENVELOPE:_S_BODY:_SolicitarCancelamentoDaCargaRESPONSE:_SolicitarCancelamentoDaCargaRESULT:_A_MENSAGEM:TEXT
			EndIf
		Else
			_lReturn := .F.
			_cResult := oWsdl:cError
			_cMensagem  := _cResult
		EndIf

		If _lOk
			_lReturn := OM521ENFPC(oProc,oWsdl,cAliasSF2)
		Else
			U_ITMsg('Falha no Cancelamento Da Carga no TMS ' + DAK->DAK_COD + CRLF + 'Erro: ' + _cMensagem,"Atenção",,1)
		EndIf
	EndIf
End Sequence

Return _lReturn

/*
===============================================================================================================================
Programa--------: OM521ENFPC
Autor-----------: Igor Melgaço
Data da Criacao-: 01/02/2024
Descrição-------: Integrações com o TMS para Exclusão de Notas Fiscais Referentes a Carga
Parametros------: oProc: Objeto do processo que chama a função
                  oWsdl: Objeto WSDL já instanciado
                  cAliasSF2: Alias da SF2
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================
*/
Static Function OM521ENFPC(oProc,oWsdl,cAliasSF2)

Local oResult
Local _cResult		:= ""
Local _cXML 		:= ""
Local _cChaveNFe 	:= ""
Local _cProtIntP	:= ""
Local _lOk 			:= .F.
Local _lReturn		:= .T.
Local _aDadosInt  := {}
Local _aCabec     := {"Status","Filial","Carga","Seq da Carga","NF","Serie","Emissao","Pedido","Retorno"}
Local _cTitulo    := "Resultado das integrações com TMS"
Local _cMsgTop    := "Exclusão de Notas Fiscais"
Local cReplace:= ""
Local cErros:= ""
Local cAvisos := ""

(cAliasSF2)->(DBGoTop())
While (cAliasSF2)->(!Eof())
	_cChaveNFe := ""
	_cProtIntP := ""

	SF2->(MsGoto((cAliasSF2)->SF2RECNO))

	DBSelectArea("SC5")
	If !SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))

		oWsdl:SetOperation( "ExcluirNotaFiscalPorChave") // Define qual operação será realizada.

		oProc:cCaption := ("Excluindo a Nota Fiscal "+_cCarga+" ...")
		ProcessMessages()

		_cChaveNFe := SF2->F2_CHVNFE
		_cProtIntP := SC5->C5_I_CDTMS

		_cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:dom="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.WebService.Carga" xmlns:dom1="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.Embarcador.Pessoas" xmlns:dom2="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.Embarcador.Localidade" xmlns:dom3="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor" xmlns:dom4="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.Embarcador.Carga" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:dom5="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.WebService">'
		_cXML += '   	<soapenv:Header>'
		_cXML += '		<Token xmlns="Token">'+_cToken+'</Token>'
		_cXML += '	</soapenv:Header>'
		_cXML += '   <soapenv:Body>'
		_cXML += '      <tem:ExcluirNotaFiscalPorChave>'
		_cXML += '         <tem:protocolo>'
		_cXML += '            <dom:protocoloIntegracaoCarga>'+_cProtIntC+'</dom:protocoloIntegracaoCarga>'
		_cXML += '            <dom:protocoloIntegracaoPedido>'+_cProtIntP+'</dom:protocoloIntegracaoPedido>'
		_cXML += '         </tem:protocolo>'
		_cXML += '         <tem:chaveNFe>'+_cChaveNFe+'</tem:chaveNFe>'
		_cXML += '      </tem:ExcluirNotaFiscalPorChave>'
		_cXML += '   </soapenv:Body>'
		_cXML += '</soapenv:Envelope>'

		// Envia para o servidor
		_lOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da TMS.

		If _lOk
			_cResult := oWsdl:GetParsedResponse() // Pega o resultado de envio já no formato em string.
			oResult  := XmlParser(oWsdl:GetSoapResponse(), cReplace, @cErros, @cAvisos)

			If oResult:_S_ENVELOPE:_S_BODY:_ExcluirNotaFiscalPorChaveRESPONSE:_ExcluirNotaFiscalPorChaveRESULT:_A_STATUS:TEXT == "false"
				_lReturn := .F.
				_lOk     := .F.
				_cResult := oResult:_S_ENVELOPE:_S_BODY:_ExcluirNotaFiscalPorChaveRESPONSE:_ExcluirNotaFiscalPorChaveRESULT:_A_MENSAGEM:TEXT
			EndIf
		Else
			_lReturn := .F.
			_cResult := oWsdl:cError
		EndIf

	EndIf

	aAdd(_aDadosInt,{_lOk, DAK->DAK_FILIAL,DAK->DAK_COD,DAK->DAK_SEQCAR,SF2->F2_DOC,SF2->F2_SERIE,SF2->F2_EMISSAO,SC5->C5_NUM,_cResult})

	(cAliasSF2)->(DBSkip())
EndDo

If !_lReturn
	//            , _aCols    ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
	_lOK := U_ITListBox(_cTitulo,_aCabec,_aDadosInt , .T.    , 1    ,_cMsgTop ,          ,        ,         ,     ,        , )
EndIf

Return _lReturn
