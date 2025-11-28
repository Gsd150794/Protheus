/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |18/07/2025| Chamado 50433. Realização de Ajustes nas Regras para Determinar Armazém de Pedidos de Vendas do Portal-ZW_LOCAL. 
Lucas Borges  |14/09/2025| Chamado 50617. Modificada a chamada dos parâmetros para a SX6
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
Jose Gavetti  |04/10/2025| Chamado 52464. Alterada a forma de recuperar o usuário logado via schedule.
===============================================================================================================================
*/

#Include "RWMAKE.CH"
#Include "TopConn.ch"
#Include "ap5mail.ch"
#Include "TOTVS.ch"  

Static _cPictQtv  := PesqPict("SZW","ZW_QTDVEN")
Static _cArmazMat := SuperGetMV("IT_TRAMZPM",.T.,"40") // Armazem para Troca de produtos matinais qdo peso do pedido ultrapassar o Peso Max
Static _nPesoMat  := SuperGetMV("IT_PESMAT",.T.,22000) // Peso Máximo para Produtos Matinais
Static _cProdMat  := SuperGetMV("IT_PROMAT",.T.,"15") // Produtos Matinais (B1_I_BIFAM)

/* 
===============================================================================================================================
Programa----------: AOMS112
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/03/2013
Descrição---------: Central de  pedidos de vendas do Portal  - Chamado 28586
Parametros--------: _ccodcli - código de cliente para filtro automático
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS112(_ccodcli)

Default _ccodcli := ""

Private _alista := {}
Private _otemp := nil
Private _ccodclip := _ccodcli
Private _cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.T.,"05,42"))// Tipos de operações da operação trigular
Private _cOperFat       := LEFT(_cOperTriangular,2)
Private _cOperRemessa   := RIGHT(_cOperTriangular,2)
Private aarr := {}
Private aheader := {}

// Variáveis abaixo utilizadas na efetivação do pedido do portal. Na chamada do MSEXECAUTO.
Private _cOperTri   := Space(1)  // Esta variável será utilizada no fonte MT410TOK para peencher o campo operação triangular.
Private _cCodClien  := Space(6)  // Esta variável será utilizada no fonte MT410TOK para peencher o campo codigo Cliente/Venda.
Private _cLojaClie  := Space(4)  // Esta variável será utilizada no fonte MT410TOK para peencher o campo loja Cliente/Venda.

AOMS112INI()

Return

/*
===============================================================================================================================
Programa----------: U_AOMSLambert()
Autor-------------: Alex Wallauer
Data da Criacao---: 17/02/2020
Descrição---------: Para chamar do MENU DIRETO
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMSLambert()
Return AOMS112I()

/*
===============================================================================================================================
Programa----------: AOMS112INI
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Funcao que controla o processamento 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112INI()

Private lInverte	:= .F.
Private cPerg		:= 'AOMS112'
Private aCampos		:= {}

AOMS112PRC()

Return

/*
===============================================================================================================================
Programa----------: AOMS112PRC
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Função que Processa os pedidos do portal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112PRC()

Local _nControle := 0
Local _nopc      := 1
Private cMarca   := GetMark()
Private aCampos  := {}
Private cPerg	  := 'AOMS112'
Private _aItalac_F3 := {}

//   _aItalac_F3:={}         1      2         3         4          5         6                  7        8            9         10         11        12
//  (_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave,_nCpoDesc,_bCondTab, _cTitAux         , _nTamChv,_aDados     , _nMaxSel , _lFilAtual,_cMVRET,_bValida})  
aAdd(_aItalac_F3,{"MV_PAR16"   ,        ,          ,         ,         ,"Tipos de pedidos",2        ,U_AOM112F3()           } )//'F3ITLC'

_cPerg := PadR( cPerg , 10 , " " ) 
SET DATE FORMAT TO "DD/MM/YYYY"

If Pergunte( cPerg , .T. )
	// Cria o arquivo Temporario para insercao dos dados selecionados.
	FWMsgRun( , {|oproc| _nControle := AOMS112ARQ(oproc, .T., .F.) }, "Aguarde!" , 'Lendo Dados dos pedidos...' )
	_nopc := AOMS112TRS()//Função que monta a tela para processar
EndIf

SET DATE FORMAT TO "DD/MM/YY"

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS112TRS
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Função que monta a tela para processar
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112TRS()

Local oPanel		:= Nil
Local aSize			:= {}
Local aBotoes		:= {}
Local aCoors		:= {}
Local lHtml         := (GetRemoteType() == 5) //Valida se o ambiente é SmartClientHtml

_lLoop := .F.

While .T.
		oPanel		:= Nil
		aSize			:= {}
		aBotoes		:= {}
		aCoors		:= {}

	Private oDlg1			:= Nil
	Private nHeight		:= 0
	Private nWidth		:= 0
	Private oOK := LoadBitmap(GetResources(),'LBOK')
	Private oNO := LoadBitmap(GetResources(),'LBNO')
	Private nOpca		 		:= 0
	Private cFiltro			:= "%"
	Private _aAreaCabec	:= {}
	Private _cFilPed		:= ""
	Private _cNumPed		:= ""
	Private oMark				:= Nil
	Private nQtdTit			:= 0
	Private nValTit     := 0
	Private oQtda				:= Nil
	Private oValor      := Nil
	Private _ahead  		:= { }
	Private _atams      := { }
	Private _aArmap		:= {}
	Private _aColuns 	:= {}

	// Botoes da tela.
		If MV_PAR23 <> 1 //SEM REJEITADOS
		aAdd( aBotoes , { "" , {|| AOMS112C(01),         (_lLoop:=.T.,oDlg1:End())  },"","Atualizar"		             })
		aAdd( aBotoes , { "" , {|| AOMS112C(02) 	                                },"","Pesquisar"		             })
		aAdd( aBotoes , { "" , {|| AOMS112C(03),         (_lLoop:=.T.,oDlg1:End())  },"","Filtro"                        })
		//aAdd( aBotoes , { "" , {|| AOMS112C(04) 	                                },"","Alterar filiais"               })
		EndIf	
		
		aAdd( aBotoes , { "" , {|| AOMS112C(05) 	                                },"","Visualizar Pedido"             })
		aAdd( aBotoes , { "" , {|| AOMS112C(07) 	                                },"","Legenda"                       })
		
		If MV_PAR23 <> 1 //SEM REJEITADOS
		aAdd( aBotoes , { "" , {|| AOMS112C(06),If(lHtml,(_lLoop:=.T.,oDlg1:End()),)},"","Alterar"	                     })
		aAdd( aBotoes , { "" , {|| AOMS112X(),If(lHtml,(_lLoop:=.T.,oDlg1:End()),)},"","Alterar Selecionados"	                     })
		aAdd( aBotoes , { "" , {|| AOMS112C(09),If(lHtml,(_lLoop:=.T.,oDlg1:End()),)},"","Recusar"                       })
		aAdd( aBotoes , { "" , {|| AOMS112C(08),If(lHtml,(_lLoop:=.T.,oDlg1:End()),)},"","Marcar não impresso"           })
		aAdd( aBotoes , { "" , {|| AOMS112I(  ),If(lHtml,(_lLoop:=.T.,oDlg1:End()),)},"","Importa PV TXT"                })
		aAdd( aBotoes , { "" , {|| REENVAPR(  )                                     },"","Reenv. Aprovação"              })
		aAdd( aBotoes , { "" , {|| U_AOM112AP()                                     },"","Visualização das Aprovações"   })
		EndIf	

		aAdd( aBotoes , { "" , {|| AOMS112C(10) 	                                },"","Exporta Excel"                 })
		aAdd( aBotoes , { "" , {|| AMS112PE(  )                                    },"","Listagem Pendencias"           })

	// Faz o calculo automatico de dimensoes de objetos
	aSize := MSADVSIZE()

	// Cria a tela para selecao dos pedidos
	_ctitulo := "CENTRAL DE PEDIDOS DO PORTAL"

	DEFINE MSDIALOG oDlg1 TITLE OemToAnsi(_ctitulo) From 0,0 To aSize[6],aSize[5] PIXEL

	oPanel := TPanel():New(30,0,'',oDlg1,, .T., .T.,, ,315,20,.T.,.T. )
	oFont := TFont():New('Times New Roman',,-18,.T.)

	If MV_PAR23 <> 1 //SEM REJEITADOS
	oQtda:= TSay():New(05,450,{||'Quantidade pedidos:  ' + AllTrim(transform(nQtdTit, "@E 9,999" ))},;
	oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	Else
	_nColRej:=360
	oQtda:= TSay():New(05,_nColRej,{||'Quantidade de Pedidos REJEITADOS:  ' + AllTrim(transform(nQtdTit, "@E 9,999" ))},;
	oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)
	EndIf

	oValor:= TSay():New(05,550,{||'Valor pedidos:   ' + AllTrim(transform(nValTit, "@E 999,999,999.99" ))},;
	oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)

	If MV_PAR23 <> 1 //SEM REJEITADOS
	@003,012 BUTTON "Efetivar" SIZE 060, 015 PIXEL OF oPanel ACTION (AOMS112C(11), If(lHtml,(_lLoop:=.T.,oDlg1:End()),) )
	@003,090 BUTTON "Imprimir" SIZE 060, 015 PIXEL OF oPanel ACTION (AOMS112C(12))
	Else
	@003,012 BUTTON "Imprimir" SIZE 060, 015 PIXEL OF oPanel ACTION (AOMS112C(12))
	EndIf

	If FlatMode()
		aCoors	:= GetScreenRes()
		nHeight	:= aCoors[2]
		nWidth	:= aCoors[1]
	Else
		nHeight	:= 143
		nWidth	:= 315
	EndIf

	A112OMK() //REALIZA MONTAGEM DO OMARK PARA SMARTCLIENT OU HTML

	A112MAP(,.F.) //REALIZA O MAPEAMENTO DAS COLUNAS PARA ORDENAR NA A112RA()

	//QUANDO For HTML O AARR DEVE SER ORDENADO MANUALMENTE
	If !lHtml .And. !_lLoop
		A112RA() //REORDENA O AARR PARA PERMITIR AS MODIFICAÇOES NAS COLUNAS
	EndIf

	_lLoop := .F.

	oDlg1:lMaximized:=.T.

	ACTIVATE MSDIALOG oDlg1 ON INIT ( EnchoiceBar(oDlg1,{|| nOpca := 2,},{|| nOpca := 2,oDlg1:End()},,aBotoes),;
		oPanel:Align:=CONTROL_ALIGN_TOP , oMark:Align:=CONTROL_ALIGN_ALLCLIENT, oMark:Refresh()) //
	If !_lLoop
		Exit
	EndIf

EndDo

Return nOpca

/*
===============================================================================================================================
Programa----------: AOMS112N
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Rotina de duplo clique na linha do browse
Parametros--------: cmarca - string de marcação do registro da tabela
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112N( cMarca As Character )

Local _nlinpos := 0 As Numeric
Local _coldfil := "" As Character
Local _nDesc   := 0 As Numeric
Local _lRet    := .T. As Logical

If MV_PAR23 = 1 //SÓ REJEITADOS
Return .F.
EndIf

If Len(aarr) = 0
	U_ITMsg("Não há registros para marcar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
	Return .F.
EndIf

_nlinpos := OMARK:NAT
_coldfil := aarr[_nlinpos,omark:ncolpos]
_nDesc   := aarr[oMark:Nat][A112MAP("Desconto")]

TRBF->(DBGoTo(aarr[_nlinpos,Len(aarr[OMARK:NAT])]))

If omark:ncolpos == A112MAP(Space(2))
	AOMS112LEG()//Legenda

ElseIf omark:ncolpos == A112MAP(Space(1))

	//Duplo clique na marcação
	If AllTrim(cmarca)==AllTrim(aarr[_nlinpos,A112MAP(Space(1))])
		nQtdTit--
		nValTit -= aarr[_nlinpos,A112MAP("Valor Pedido")]
		aarr[_nlinpos,01] := "  "
	Else
		nQtdTit++
		nValTit += aarr[_nlinpos,A112MAP("Valor Pedido")]
		aarr[_nlinpos,A112MAP(Space(1))] := cmarca
	EndIf

	RecLock("TRBF",.F.)
	TRBF->OK := aarr[_nlinpos,A112MAP(Space(1))]
	TRBF->(MSUnLock())


	If SubStr(omark:AARRAY[omark:NAT][A112MAP("Tipo")],1,2) $ "05;42" //.AND. Empty(AllTrim(omark:AARRAY[omark:NAT][A112MAP("Cliente/Venda")]))

		//Duplo clique para alterar o cliente de remessa de operação triangular
		_cclirem := TRBF->CLIREM //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
		_clojrem := TRBF->LOJEN
		_bValid2:= {|| AOMS112K(_cclirem,_clojrem) }
		_oDlg := nil
		_lok := .F.

		DEFINE MSDIALOG _oDlg TITLE "Cliente/Venda para pedido " + aarr[_nlinpos,A112MAP("Id Pedido")] FROM 000,000 TO 150,300 PIXEL

		@ 005, 007 Say "Cliente/Venda:" PIXEL
		@ 017, 009 MSGET _cclirem SIZE 40,11 OF _oDlg F3 "SA1" PIXEL
		@ 017, 060 MSGET _clojrem SIZE 30,11 OF _oDlg PIXEL

		@ 050,020	BMPBUTTON Type 01 ACTION Eval({|| If(EVAL(_bValid2),(_lok:=.T.,_oDlg:End()),) } )
		@ 050,060	BMPBUTTON Type 02 ACTION Eval({|| _lok := .F. , close(_oDlg)				} )

		Activate MSDialog _oDlg Centered

		If _lok

			If Empty(_cclirem)

				_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_OPTRI = ' '" +;
					" WHERE ZW_IDPED = '"+ AllTrim(aarr[_nlinpos,A112MAP("Id Pedido")]) +;
					"' AND D_E_L_E_T_ = ' ' " )
			Else

				_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_OPTRI = 'F'" +;
					" WHERE ZW_IDPED = '"+ AllTrim(aarr[_nlinpos,A112MAP("Id Pedido")]) +;
					"' AND D_E_L_E_T_ = ' ' " )
			EndIf

			_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_CLIREM = '" + _cclirem  + "'" +;
				" WHERE ZW_IDPED = '"+ AllTrim(aarr[_nlinpos,A112MAP("Id Pedido")]) +;
				"' AND D_E_L_E_T_ = ' ' " )

			_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_LOJEN = '" + _clojrem  + "'" +;
				" WHERE ZW_IDPED = '"+ AllTrim(aarr[_nlinpos,A112MAP("Id Pedido")]) +;
				"' AND D_E_L_E_T_ = ' ' " )

			_nRet:=TcSqlExec( "COMMIT" )

			TRBF->(DBGoTo(aarr[_nlinpos,Len(aarr[OMARK:NAT])]))

			//RecLock("TRBF",.F.)
			TRBF->CLIREM := AllTrim(_cclirem)  //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
			TRBF->LOJEN := AllTrim(_clojrem)
			//TRBF->(MSUnLock())

			If Empty(_cclirem)
				aarr[_nlinpos,A112MAP("Cliente/Venda")] :=  "  "
			Else
				aarr[_nlinpos,A112MAP("Cliente/Venda")] := TRBF->CLIREM + "/" + TRBF->LOJEN + " - " + Posicione("SA1",1,xFilial("SA1")+AllTrim(TRBF->CLIREM)+AllTrim(TRBF->LOJEN),"A1_NOME") //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
			EndIf

		EndIf

		omark:refresh()
	EndIf


ElseIf omark:ncolpos == A112MAP("Filial Faturamento")

	//Duplo clique para alterar a filial de faturamento

	_lRet:=leditcell(@aarr,omark,"",A112MAP("Filial Faturamento"))
	If _lRet .And. U_AOM112Val('FilFatBrowse')
		omark:godown()
	ElseIf _lRet
		aarr[_nlinpos,omark:ncolpos] := 	_coldfil
	EndIf
	omark:refresh()

ElseIf omark:ncolpos == A112MAP("Filial Carregamento")

	//Duplo clique para alterar a filial de carregamento
	_lRet:=leditcell(@aarr,omark,"",A112MAP("Filial Carregamento"))
	If _lRet .And. U_AOM112Val('FilProBrowse')
		omark:godown()
	ElseIf _lRet
		aarr[_nlinpos,omark:ncolpos] := 	_coldfil
	EndIf
	omark:refresh()
ElseIf omark:ncolpos == A112MAP("Tipo")

	//Duplo clique para alterar a filial de carregamento
	_lRet:=leditcell(@aarr,omark,"",A112MAP("Tipo"))
	If _lRet .And. U_AOM112Val('TipoBrowse')
		omark:godown()
	ElseIf _lRet 
		aarr[_nlinpos,omark:ncolpos] := 	_coldfil
	EndIf
	omark:refresh()
ElseIf omark:ncolpos == A112MAP("Desconto")
	//Duplo clique para alterar o valor do desconto
	If AARR[oMark:Nat][A112MAP("Tp Frete")] == "FOB"
		_lRet:=leditcell(@aarr,omark,"@E 999,999,999.99",A112MAP("Desconto"))
		If _lRet .And. U_AOM112Val("DescBrowser")
			omark:godown()
		ElseIf _lRet 
			AARR[oMark:Nat][A112MAP("Desconto")] := _nDesc
		EndIf
	EndIf
	omark:refresh()

ElseIf omark:ncolpos == A112MAP("Cliente/Venda")
	If SubStr(omark:AARRAY[omark:NAT][A112MAP("Tipo")],1,2) $ "05;42"
		//Duplo clique para alterar o cliente de remessa de operação triangular
		_cclirem := TRBF->CLIREM //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
		_clojrem := TRBF->LOJEN
		_bValid2:= {|| AOMS112K(_cclirem,_clojrem) }
		_oDlg := nil
		_lok := .F.

		DEFINE MSDIALOG _oDlg TITLE "Cliente/Venda para pedido " + aarr[_nlinpos,A112MAP("Id Pedido")] FROM 000,000 TO 150,300 PIXEL

		@ 005, 007 Say "Cliente/Venda:" PIXEL
		@ 017, 009 MSGET _cclirem SIZE 40,11 OF _oDlg F3 "SA1" PIXEL
		@ 017, 060 MSGET _clojrem SIZE 30,11 OF _oDlg PIXEL

		@ 050,020	BMPBUTTON Type 01 ACTION Eval({|| If(EVAL(_bValid2),(_lok:=.T.,close(_oDlg)),) } )
		@ 050,060	BMPBUTTON Type 02 ACTION Eval({|| _lok := .F. , close(_oDlg)				} )

		Activate MSDialog _oDlg Centered

		If _lok

			If Empty(_cclirem)

				_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_OPTRI = ' '" +;
					" WHERE ZW_IDPED = '"+ AllTrim(aarr[_nlinpos,A112MAP("Id Pedido")]) +;
					"' AND D_E_L_E_T_ = ' ' " )
			Else

				_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_OPTRI = 'F'" +;
					" WHERE ZW_IDPED = '"+ AllTrim(aarr[_nlinpos,A112MAP("Id Pedido")]) +;
					"' AND D_E_L_E_T_ = ' ' " )
			EndIf

			_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_CLIREM = '" + _cclirem  + "'" +;
				" WHERE ZW_IDPED = '"+ AllTrim(aarr[_nlinpos,A112MAP("Id Pedido")]) +;
				"' AND D_E_L_E_T_ = ' ' " )

			_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_LOJEN = '" + _clojrem  + "'" +;
				" WHERE ZW_IDPED = '"+ AllTrim(aarr[_nlinpos,A112MAP("Id Pedido")]) +;
				"' AND D_E_L_E_T_ = ' ' " )

			_nRet:=TcSqlExec( "COMMIT" )

			TRBF->(DBGoTo(aarr[_nlinpos,Len(aarr[OMARK:NAT])]))

			RecLock("TRBF",.F.)
			TRBF->CLIREM := AllTrim(_cclirem)
			TRBF->LOJEN := AllTrim(_clojrem)
			TRBF->(MSUnLock())

			If Empty(_cclirem)
				aarr[_nlinpos,A112MAP("Cliente/Venda")] :=  "  "
			Else
				aarr[_nlinpos,A112MAP("Cliente/Venda")] := TRBF->CLIREM + "/" + TRBF->LOJEN + " - " + Posicione("SA1",1,xFilial("SA1")+AllTrim(TRBF->CLIREM)+AllTrim(TRBF->LOJEN),"A1_NOME") //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
			EndIf

		EndIf

		omark:refresh()
	EndIf

Else

	//Duplo clique na marcação
	If AllTrim(cmarca)==AllTrim(aarr[_nlinpos,A112MAP(Space(1))])
		nQtdTit--
		nValTit -= aarr[_nlinpos,A112MAP("Valor Pedido")]
		aarr[_nlinpos,A112MAP(Space(1))] := "  "
	Else
		nQtdTit++
		nValTit += aarr[_nlinpos,A112MAP("Valor Pedido")]
		aarr[_nlinpos,A112MAP(Space(1))] := cmarca
	EndIf

	RecLock("TRBF",.F.)
	TRBF->OK := aarr[_nlinpos,A112MAP(Space(1))]
	TRBF->(MSUnLock())
EndIf

oQtda:Refresh()
oValor:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS112ALL
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Rotina para inverter a marcacao de todos os registros.
Parametros--------: cMarca - string de marcação da tabela
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112ALL( cMarca  )

Local _nlinpos := 0 As Numeric
Local nReg     := 0 As Numeric
Local _nnp     := 1 As Numeric

If Len(aarr) = 0
	U_ITMsg("Não há registros para marcar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
	Return .F.
EndIf

_nlinpos := omark:nat
nReg     := aarr[_nlinpos,Len(aarr[OMARK:NAT])]

For _nnp := 1 to Len(aarr)
	TRBF->(DBGoTo(aarr[_nnp,Len(aarr[OMARK:NAT])]))
	If AllTrim(aarr[_nnp,A112MAP(Space(1))]) == AllTrim(cmarca)
		TRBF->( RecLock( "TRBF" , .F. ) )
		TRBF->OK := Space(2)
		TRBF->( MSUnLock() )
		aarr[_nnp,A112MAP(Space(1))] := Space(2)
		nQtdTit--
		nValTit -= aarr[_nnp,A112MAP("Valor Pedido")]
	Else
		TRBF->( RecLock( "TRBF" , .F. ) )
		TRBF->OK := cMarca
		TRBF->( MSUnLock() )
		aarr[_nnp][1] := cMarca
		nQtdTit++
		nValTit += aarr[_nnp,A112MAP("Valor Pedido")]
	EndIf
	nQtdTit := IIf( nQtdTit < 0 , 0 , nQtdTit )
Next

TRBF->( DBGoTo(nReg) )
oQtda:Refresh()
oValor:Refresh()
oMark:Refresh()
ProcessMessages()

Return

/*
===============================================================================================================================
Programa----------: AOMS112arq
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Rotina para criação do arquivo temporário
Parametros--------: oproc - objeto da barra de processamento
										_lini - inicializa campos de data de necessidade
										_lcabec - inicializa campos de cabecalho
										_lmantem - mantem marcados
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112arq(oproc,_lini,_lcabec,_lmantem)

Local aEstru		:= {}
Local _lp			:= 0
Local _cTempoPend, _cHoraPend, _nDiasPend
Local lHtml:= (GetRemoteType() == 5)
Local _cFilCarreg := ""
Local _ndias      := 0
Local nQtdRegs := 0

Private aheader := {{1,"C6_ITEM"},{2,"C6_PRODUTO"},{3,"C6_LOCAL"}}
Private acols := {}
Default _lini := .F.
Default _lcabec := .T.
Default _lmantem := .F.

//garante que o pergunte está correto
Pergunte( cPerg , .F. )

MV_PAR06 := 2 //Desabilitar simulador

// Armazena no array aEstru a estrutura dos campos da tabela.
aEstru := {	{ "OK"			, "C" , 002 , 0 } ,;
	{ "OK2"		    , "C" , 001 , 0 } ,;
	{ "IMPRIME"  	, "C" , 010 , 0 } ,;
	{ "FILIAL"	  	, "C" , 040 , 0 } ,;
	{ "FILPRO"	  	, "C" , 040 , 0 } ,;
	{ "FILCR"	    , "C" , 020 , 0 } ,;
	{ "RFILIAL"	  	, "C" , 002 , 0 } ,;
	{ "NUMPED"	   	, "C" , 025 , 0 } ,;
	{ "TIPO"	    , "C" , 002 , 0 } ,;
	{ "VEND1"       , "C" , 006 , 0 } ,;
	{ "NMVEND1"     , "C" , 020 , 0 } ,;
	{ "REDE"        , "C" , 006 , 0 } ,;
	{ "NMREDE"      , "C" , 030 , 0 } ,;
	{ "CODCLI"	  	, "C" , 006 , 0 } ,;
	{ "LOJA"	 	, "C" , 004 , 0 } ,;
	{ "NMCLI"	    , "C" , 060 , 0 } ,;
	{ "TIPOCLI"	  	, "C" , 001 , 0 } ,;
	{ "CONDPAGTO"  	, "C" , 003 , 0 } ,;
	{ "VEND2"     	, "C" , 006 , 0 } ,;
	{ "NMVEND2"   	, "C" , 060 , 0 } ,;
	{ "TAB_PREC"  	, "C" , 003 , 0 } ,;
	{ "DTEMISS"   	, "C" , 010 , 0 } ,;
	{ "TPFRETE"   	, "C" , 001 , 0 } ,;
	{ "TRANSP"	   	, "C" , 006 , 0 } ,;
	{ "DESPESA"     , "N" , 014 , 2 } ,;
	{ "VALOR"       , "N" , 014 , 2 } ,;
	{ "MENSANF"     , "C" , 300 , 0 } ,;
	{ "TPCAR"       , "C" , 001 , 0 } ,;
	{ "OBSCOMER"    , "C" , 300 , 0 } ,;
	{ "HORAENTR"    , "C" , 005 , 0 } ,;
	{ "SENHA"       , "C" , 014 , 0 } ,;
	{ "DT_ENTREG"   , "C" , 010 , 0 } ,;
	{ "BLQLCR" 	    , "C" , 001 , 0 } ,;
	{ "BLOPRC" 	    , "C" , 001 , 0 } ,;
	{ "BLOCLI" 	    , "C" , 001 , 0 } ,;
	{ "BLOQ" 	    , "C" , 001 , 0 } ,;
	{ "STAT_ZW"     , "C" , 002 , 0 },;
	{ "STATUS1"     , "C" , 020 , 0 },;
	{ "STATUS2"     , "C" , 020 , 0 },;
	{ "STATUS3"     , "C" , 020 , 0 },;
	{ "OPTRI"       , "C" , 001 , 0 },;
	{ "CLIREM"      , "C" , 006 , 0 },;
	{ "LOJEN"       , "C" , 004 , 0 },;
	{ "BLQPRC"      , "C" , 004 , 0 },;
	{ "ENVWF"       , "C" , 001 , 0 },;
	{ "NIVELWF"     , "C" , 001 , 0 },;
	{ "MOTLP"       , "C" , 004 , 0 },;
	{ "TEMPOPEND"   , "C" , 040 , 0 },;
	{ "PESO"		, "N" , 013 , 4 },;
	{ "DESCONTO"	, "N" , 014 , 2 },;
	{ "NMMVEND2"	, "C" , 060 , 0 },;
	{ "NMVEND3"		, "C" , 060 , 0 }}

// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
If Select("TRBF") > 0
	oproc:cCaption := ("Apagando temporário...")
	ProcessMessages()
	If ValType(_otemp) == "O"
		TRBF->(DBCloseArea())
		_otemp:Delete()
	Else
		TRBF->(DBCloseArea())
	EndIf
EndIf

oproc:cCaption := ("Criando arquivo temporário...")
ProcessMessages()
_otemp := FWTemporaryTable():New( "TRBF", aEstru )

oproc:cCaption := ("Criando indices do arquivo temporário...")
ProcessMessages()
_otemp:AddIndex( "PD", {"NUMPED"} )
_otemp:AddIndex( "CL", {"CODCLI"} )
_otemp:AddIndex( "NM", {"NMCLI"} )
_otemp:AddIndex( "NR", {"NMREDE"} )

_otemp:Create()

// Query para selecao dos dados DOS PEDIDOS
_cQuery := " SELECT "
_cQuery += " Case WHEN ZW_TIPO = '10' THEN 'A ' Else 'B' END ORD , "
_cQuery += "     SZW.ZW_FILIAL     FILIAL   ,"
_cQuery += "     SZW.ZW_FILPRO     ZW_FILPRO,"
_cQuery += "     SZW.ZW_TIPO       TIPO     ,"
_cQuery += "     SZW.ZW_CLIENTE    CODCLI   ,"
_cQuery += "     SZW.ZW_LOJACLI    LOJA     ,"
_cQuery += "     SZW.ZW_CLIENT     CODCLIENT,"
_cQuery += "     SZW.ZW_LOJAENT    LOJAENT  ,"
_cQuery += "     SZW.ZW_TIPOCLI    TIPOCLI  ,"
_cQuery += "     SZW.ZW_CONDPAG    CONDPAGTO,"
_cQuery += "     SZW.ZW_VEND1      VEND1    ,"
_cQuery += "     SA3.A3_SUPER      VEND2    ," // COORDENADOR
_cQuery += "     SA3.A3_GEREN      VEND3    ," // GERENTE
_cQuery += "     SA3.A3_I_SUPE     VEND4    ,"
_cQuery += "     SUM(SZW.ZW_DESC1) DESC1    ,"
_cQuery += "     SUM(SZW.ZW_DESC2) DESC2    ,"
_cQuery += "     SUM(SZW.ZW_DESC3) DESC3    ,"
_cQuery += "     SUM(SZW.ZW_DESC4) DESC4    ,"
_cQuery += "     SZW.ZW_TABELA     TAB_PREC ,"
_cQuery += "     SZW.ZW_EMISSAO    DTEMISS  ,"
_cQuery += "     SZW.ZW_TPFRETE    TPFRETE  ,"
_cQuery += "     SZW.ZW_TRANSP     TRANSP   ,"
_cQuery += "     SZW.ZW_DESPESA    DESPESA  ,"
_cQuery += "     SZW.ZW_MENNOTA    MENSANF  ,"
_cQuery += "     SZW.ZW_I_AGEND     TPCAR    ,"
_cQuery += "     SZW.ZW_OBSCOM     OBSCOMER ,"
_cQuery += "     SZW.ZW_HOREN      HORAENTR ,"
_cQuery += "     SZW.ZW_SENHA      SENHA    ,"
_cQuery += "     SZW.ZW_FECENT     DT_ENTREG,"
_cQuery += "     SZW.ZW_EVENTO     EVENTO   ,"
_cQuery += "     SZW.ZW_STATUS     STAT_ZW  ,"
_cQuery += "     SZW.ZW_IDPED      NUMPED   ,"
_cQuery += "     SZW.ZW_BLQLCR     BLQLCR   ,"
_cQuery += "     SZW.ZW_OPTRI      OPTRI    ,"
_cQuery += "     SZW.ZW_CLIREM     CLIREM   ,"
_cQuery += "     SZW.ZW_LOJEN      LOJEN    ,"
_cQuery += "     SZW.ZW_BLOPRC     BLQPRC   ,"
_cQuery += "     SZW.ZW_ENVWF      ENVWF    ,"
_cQuery += "     SZW.ZW_NIVELWF    NIVELWF  ,"
_cQuery += "     SZW.ZW_MOTLP      MOTLP    ,"

_cQuery += "     (select SUM(SZW3.ZW_PRCVEN*SZW3.ZW_QTDVEN) from " + RETSQLNAME("SZW") + " SZW3  where SZW3.d_e_l_e_t_ = ' ' and SZW3.ZW_FILIAL = SZW.ZW_FILIAL and szw3.zw_idped = SZW.ZW_IDPED )   VALOR,"
_cQuery += "     (SELECT SUM(B1_PESBRU * SZW4.ZW_QTDVEN ) FROM "+ RetSqlName("SZW")+" SZW4 JOIN "+RetSqlName("SB1")+" ON B1_COD = ZW_PRODUTO WHERE SZW4.ZW_IDPED =  SZW.ZW_IDPED AND SZW4.D_E_L_E_T_ = ' ') PESO,"
_cQuery += "     ZW_FOBDESC DESCONTO,"

_cQuery += "     (SELECT ZW_BLOPRC from "+ RETSQLNAME('SZW') + " SZW2  where SZW2.d_e_l_e_t_ = ' ' and SZW2.ZW_FILIAL = SZW.ZW_FILIAL and szw2.zw_idped = SZW.ZW_IDPED "
_cQuery +=                              " and SZW2.ZW_BLOPRC <> ' ' and rownum = 1)     BLOPRC   ,"
_cQuery += "     SZW.ZW_IMPRIME    IMPRIME  ,"
_cQuery += "     SZW.ZW_BLOQ       BLOQ     , "
_cQuery += "     SZW.ZW_TPVENDA    TPVENDA , SZW.ZW_HORAINC HORAINC  "
_cQuery += " FROM  "+ RETSQLNAME('SZW') +" SZW , "+ RETSQLNAME('SA3') +" SA3 "
_cQuery += " WHERE "+ RETSQLDEL('SZW,SA3')
_cQuery += " AND SA3.A3_FILIAL = '"+ xFilial("SA3") +"' "
_cQuery += " AND SA3.A3_COD = SZW.ZW_VEND1 "
_cQuery += " AND SZW.ZW_ITEM = '1 ' "
_cQuery += " AND SZW.ZW_NUMPED = ' '"

If MV_PAR23 = 1 //SÓ REJEITADOS
	_cQuery += " AND SZW.ZW_STATUS IN ('	Q','R','E','C') "
Else
	_cQuery += " AND SZW.ZW_STATUS IN ('L','P','D','B','E','C') "
	_cQuery += " AND ( SZW.ZW_ENVWF <> ' ' or SA3.A3_I_VBROK = 'B' ) " //Somente listar Pedido que já foi avaliado pela rotina MOMS050 - WF DE PREÇO
EndIf

// Incluída chamada inicial filtrando por código do Cliente 
If Empty( _cCodClip )

	If !Empty(MV_PAR02)
		_cQuery += " AND SA3.A3_SUPER  IN "+ FormatIn( MV_PAR02 , ";" )
	EndIf

	If !Empty(MV_PAR01)
		_cQuery += " AND SA3.A3_GEREN  IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf

	If !Empty(MV_PAR03)
		_cQuery += " AND SA3.A3_I_SUPE  IN "+ FormatIn( MV_PAR02 , ";" )
	EndIf

	If !Empty(MV_PAR04)
		_cQuery += " AND SZW.ZW_VEND1  IN "+ FormatIn( MV_PAR04 , ";" )
	EndIf

	If !Empty(MV_PAR05)
		_cQuery += " AND SZW.ZW_FILIAL IN "+ FormatIn( MV_PAR05 , ";" )
	EndIf

	If !Empty(MV_PAR07)
		_cQuery += " AND SZW.ZW_FECENT >= '"+ DToS( MV_PAR07 ) + "' "
	EndIf

	If !Empty(MV_PAR08)
		_cQuery += " AND SZW.ZW_FECENT <= '"+ DToS( MV_PAR08 ) + "' "
	EndIf

	If !Empty(MV_PAR09)
		_cQuery += " AND SZW.ZW_EMISSAO >= '"+ DToS( MV_PAR09 ) + "' "
	EndIf

	If !Empty(MV_PAR10)
		_cQuery += " AND SZW.ZW_EMISSAO <= '"+ DToS( MV_PAR10 ) + "' "
	EndIf

	If !Empty(MV_PAR11)
		_cQuery += " AND SZW.ZW_CLIENTE >= '"+  MV_PAR11 + "' "
	EndIf

	If !Empty(MV_PAR12)
		_cQuery += " AND SZW.ZW_LOJACLI >= '"+  MV_PAR12 + "' "
	EndIf

	If !Empty(MV_PAR13)
		_cQuery += " AND SZW.ZW_CLIENTE <= '"+  MV_PAR13  + "' "
	EndIf

	If !Empty(MV_PAR14)
		_cQuery += " AND SZW.ZW_LOJACLI <= '"+  MV_PAR14 + "' "
	EndIf

	If !Empty(MV_PAR15)
		_cQuery += " AND (SELECT A1_GRPVEN FROM "+ RETSQLNAME('SA1') +" SA1 "
		_cQuery += " WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_COD = SZW.ZW_CLIENTE AND SA1.A1_LOJA = SZW.ZW_LOJACLI "
		_cQuery += " AND ROWNUM = 1) IN "+ FormatIn( MV_PAR15 , ";" )
	EndIf

	If ValType(MV_PAR18) <> "C" 
		MV_PAR18:=""
	EndIf
	If !Empty(MV_PAR18)
		_cQuery += " AND SZW.ZW_I_AGEND IN "+ FormatIn( MV_PAR18 , ";" )
	EndIf

	If MV_PAR19 == 2
		_cQuery += " AND ZW_IMPRIME <> '1' "
	ElseIf MV_PAR19 == 1
		_cQuery += " AND ZW_IMPRIME = '1' "
	EndIf

	If MV_PAR20 == 1
		_cQuery += " AND ZW_TPFRETE = 'C' "
	ElseIf MV_PAR20 == 2
		_cQuery += " AND ZW_TPFRETE = 'F' "
	EndIf

	If MV_PAR21 <> 4
		_cQuery += " AND (SELECT A1_I_CLABC FROM "+ RETSQLNAME('SA1') +" SA1 "
		_cQuery += " WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_COD = SZW.ZW_CLIENTE AND SA1.A1_LOJA = SZW.ZW_LOJACLI "
		_cQuery += " AND ROWNUM = 1) = '"+Str(MV_PAR21,1)+"' "
	EndIf

Else

	_cQuery += " AND SZW.ZW_CLIENTE = '"+ _cCodCli +"' "

EndIf

_cQuery += " AND SZW.ZW_VEND1 = SA3.A3_COD "
_cQuery += " GROUP BY SZW.ZW_FILIAL , SZW.ZW_TIPO   , SZW.ZW_CLIENTE , SZW.ZW_LOJACLI , SZW.ZW_CLIENT  , SZW.ZW_LOJAENT , SZW.ZW_TIPOCLI , SZW.ZW_CONDPAG , SZW.ZW_VEND1   , SA3.A3_SUPER  , "
_cQuery += "          SA3.A3_GEREN  , SA3.A3_I_SUPE , SZW.ZW_TABELA  , SZW.ZW_EMISSAO , SZW.ZW_TPFRETE , SZW.ZW_TRANSP  , SZW.ZW_DESPESA , SZW.ZW_MENNOTA , SZW.ZW_I_AGEND , SZW.ZW_FILPRO , "
_cQuery += "          SZW.ZW_OBSCOM , SZW.ZW_HOREN  , SZW.ZW_SENHA   , SZW.ZW_FECENT  , SZW.ZW_EVENTO  , SZW.ZW_STATUS  , SZW.ZW_IDPED   , SZW.ZW_IMPRIME , SZW.ZW_BLOPRC  , SZW.ZW_BLQLCR , "
_cQuery += "          SZW.ZW_OPTRI  , SZW.ZW_CLIREM , SZW.ZW_LOJEN   , SZW.ZW_ENVWF   , SZW.ZW_NIVELWF , SZW.ZW_MOTLP   , SZW.ZW_FOBDESC , SZW.ZW_TPVENDA , SZW.ZW_HORAINC , SZW.ZW_BLOQ     "
_cQuery += " ORDER BY ORD, SZW.ZW_FILIAL, SZW.ZW_IDPED "


oproc:cCaption := ("Carregando query de pedidos...")
ProcessMessages()

If Select("TRB") > 0
	TRB->(DBCloseArea())
EndIf

TCQUERY _cQuery NEW ALIAS "TRB"

oproc:cCaption := ("Contando os pedidos...")
ProcessMessages()

nQtdTit := 0
COUNT TO nQtdTit

nQtdRegs := nQtdTit
TRB->(DBGoTop())
_npv:=1

If _lmantem

	//Guarda pedidos marcados
	_citens := ""
	For _lp := 1 to Len(aarr)

		If !Empty(aarr[_lp][1])
			_citens += ";" + AllTrim(aarr[_lp][8])
		EndIf

	Next

EndIf

aarr := {}


While TRB->(!Eof())

	//Atualiza régua
	oproc:cCaption := ("Processando pedidos do portal... ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	ProcessMessages()

	//Se é entrega imediata força data de entrega para primeiro dia possível com transit time
	If	AllTrim(TRB->TPCAR) $ 'I/O'//I=Imediata //O=Agendada pelo Op.Log.
		_cFilCarreg := TRB->FILIAL
		If !Empty(TRB->ZW_FILPRO) .And. !(AllTrim(TRB->ZW_FILPRO)=='0')
			_cFilCarreg := TRB->ZW_FILPRO
		EndIf
	EndIf

	//Mantém registros marcados
	If _lmantem .And. AllTrim(TRB->NUMPED) $ _CITENS
		_cok := cmarca
	Else
		_cok := ""
	EndIf

	// Calcula o tempo pendente.
	_cHoraPed    := TRB->HORAINC + ":00"
	_cTempoPend  := ""
	_cHoraPend   :=ElapTime(_cHoraPed,Time() )
	_nDiasPend   := Date() - SToD( TRB->DTEMISS )
	If _nDiasPend == 0
		_cTempoPend  := _cHoraPend + " Horas  Hr. Incl: " + TRB->HORAINC
	Else
		_cTempoPend  := AllTrim(Str(_nDiasPend,10)) + " Dia(s) Hr. Incl: " + TRB->HORAINC
	EndIf

	RecLock("TRBF",.T.)
	TRBF->OK		    		:= _cok
	TRBF->OK2		    		:= ""
	TRBF->IMPRIME				:= IIf( Empty( TRB->IMPRIME ) , "2" , TRB->IMPRIME ) +"-"+ IIf( TRB->IMPRIME == '1' , "SIM" , "NÃO" )
	TRBF->FILIAL	    		:= TRB->FILIAL   +" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(TRB->FILIAL,1,2),1,"")
	TRBF->FILPRO     			:= If((Empty(TRB->ZW_FILPRO) .Or. (AllTrim(TRB->ZW_FILPRO)=='0')),TRB->FILIAL,TRB->ZW_FILPRO)//Se o FILPRO em branco ou errado preenche com o FILIAL
	TRBF->FILPRO     			:= SubStr(TRBF->FILPRO,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(TRBF->FILPRO,1,2),1,"")
	TRBF->FILCR     			:= TRB->FILIAL
	TRBF->RFILIAL    			:= TRB->FILIAL
	TRBF->NUMPED 				:= TRB->NUMPED
	TRBF->VALOR 				:= TRB->VALOR
	TRBF->TIPO   				:= TRB->TIPO
	TRBF->CODCLI 				:= TRB->CODCLI
	TRBF->LOJA 					:= TRB->LOJA
	TRBF->NMCLI					:= GetAdvFVal( "SA1" , "A1_NOME" , xFilial("SA1") + TRB->CODCLI + TRB->LOJA , 1 , "" )
	TRBF->TIPOCLI				:= TRB->TIPOCLI
	TRBF->CONDPAGTO  	    	:= TRB->CONDPAGTO
	TRBF->VEND1 				:= TRB->VEND1
	TRBF->NMVEND1				:= GetAdvFVal( "SA3" , "A3_NOME" , xFilial("SA3") + TRB->VEND1 , 1 , "" )
	TRBF->VEND2					:= TRB->VEND2
	TRBF->NMVEND2				:= GetAdvFVal( "SA3" , "A3_NOME" , xFilial("SA3") + TRB->VEND2 , 1 , "" )
	TRBF->TAB_PREC		    	:= TRB->TAB_PREC
	TRBF->DTEMISS				:= DToC( SToD( TRB->DTEMISS ) )
	TRBF->TPFRETE				:= TRB->TPFRETE
	TRBF->TRANSP				:= TRB->TRANSP
	TRBF->DESPESA				:= TRB->DESPESA
	TRBF->MENSANF				:= TRB->MENSANF
	TRBF->TPCAR					:= TRB->TPCAR
	TRBF->OBSCOMER		    	:= TRB->OBSCOMER
	TRBF->HORAENTR		    	:= TRB->HORAENTR
	TRBF->SENHA					:= TRB->SENHA
	TRBF->DT_ENTREG		    	:= DToC( SToD( TRB->DT_ENTREG ) )
	TRBF->STAT_ZW				:= TRB->STAT_ZW
	TRBF->BLQLCR				:= TRB->BLQLCR
	TRBF->BLOPRC				:= TRB->BLOPRC
	TRBF->BLOCLI				:= Posicione("SA1",1,xFilial("SA1")+TRB->CODCLI+TRB->LOJA,"A1_MSBLQL")
	TRBF->BLOQ    		    	:= TRB->BLOQ
	TRBF->OPTRI   		        := TRB->OPTRI
	TRBF->CLIREM				:= TRB->CLIREM //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
	TRBF->LOJEN					:= TRB->LOJEN
	TRBF->BLQPRC				:= TRB->BLQPRC
	TRBF->ENVWF					:= AllTrim(TRB->ENVWF)
	TRBF->MOTLP					:= TRB->MOTLP
	TRBF->TEMPOPEND             := _cTempoPend
	TRBF->PESO					:= TRB->PESO
	TRBF->DESCONTO				:= TRB->DESCONTO
	TRBF->NMMVEND2				:= TRB->VEND2 + " - " + GetAdvFVal( "SA3" , "A3_NOME" , xFilial("SA3") + TRB->VEND2 , 1 , "" )
	TRBF->NMVEND3				:= TRB->VEND3 + " - " + GetAdvFVal( "SA3" , "A3_NOME" , xFilial("SA3") + TRB->VEND3 , 1 , "" )

	//Se cliente está bloqueado e status de crédito não está como Z atualiza a SZW
	If TRBF->BLOCLI == "1" .And. TRBF->BLQLCR != "Z" .And. TRBF->BLQLCR != "R"

		SZW->(DBSetOrder(1))
		If SZW->(DBSeek(TRB->FILIAL+TRB->NUMPED))

			While SZW->ZW_FILIAL == TRB->FILIAL .And. SZW->ZW_IDPED == TRB->NUMPED

				RecLock("SZW",.F.)
				SZW->ZW_BLQLCR := "Z"
				SZW->ZW_I_MOTBL := "CLIENTE BLOQUEADO"
				SZW->ZW_DTAVAC := Date()
				SZW->ZW_HRAVAC := Time()
				SZW->(MSUnLock())

				SZW->(DBSkip())
			EndDo
		EndIf
	EndIf

	_linclui := .T.

	If MV_PAR06 == 1

		_ccor := U_AOMS1128(TRBF->(Recno()))

		RecLock("TRBF",.F.)
		TRBF->STATUS1 := _ccor
		TRBF->(MSUnLock())

		If  (MV_PAR17 == 1 .And. AllTrim(TRBF->STATUS1) != "VERDE") .Or. (MV_PAR17 == 2 .And. AllTrim(TRBF->STATUS1) != "VERMELHO")
			RecLock("TRBF",.F.)
			TRBF->(Dbdelete())
			TRBF->(MSUnLock())
			_linclui := .F.
		EndIf
	EndIf

	//Filtra status da legenda principal
	_acor := U_AOMS1129(TRBF->(Recno()),.T.)
	_ncor := _acor[1]
	_ccor := _acor[2]

	RecLock("TRBF",.F.)
	TRBF->STATUS2 := AllTrim(StrZero(_ncor,2))
	TRBF->STATUS3 := AllTrim(_CCOR)
	TRBF->(MSUnLock())

	If !Empty(MV_PAR16)
		If MV_PAR23 <> 1 .And. !(AllTrim(TRBF->STATUS2) $ MV_PAR16)//FILTRO POR LEGERNDA
			_linclui := .F.

			RecLock("TRBF",.F.)
			TRBF->(Dbdelete())
			TRBF->(MSUnLock())
		EndIf
	EndIf

	_npv++

	If _linclui
		_cFilCarreg := TRB->FILIAL
		If !Empty(TRB->ZW_FILPRO) .And. !(AllTrim(TRB->ZW_FILPRO)=='0')
			_cFilCarreg := TRB->ZW_FILPRO
		EndIf

		_cliremessa := IIf(Empty(TRBF->CLIREM),"  ",TRBF->CLIREM + "/" + TRBF->LOJEN + " - " + Posicione("SA1",1,xFilial("SA1")+AllTrim(TRBF->CLIREM)+AllTrim(TRBF->LOJEN),"A1_NOME") ) //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
		If !lHtml
			aAdd(aarr,{	_cok,;                              // 01
			"  ",;                                          // 02
			"  ",;                                          // 03
			AllTrim(TRBF->IMPRIME),;                        // 04
			TRBF->TIPO + " - " + SubStr(Posicione("ZB4",1,xFilial("ZB4")+TRBF->TIPO,"ZB4_DESCRI"),1,20),;  // 05
			AllTrim(TRBF->FILIAL) ,;                        // 06
			TRBF->FILPRO ,;                                 // 07
			AllTrim(TRBF->NUMPED) ,;                        // 08
			AllTrim(TRBF->CODCLI) + "/" + AllTrim(TRBF->LOJA) + " - " + Posicione("SA1",1,xFilial("SA1")+AllTrim(TRBF->CODCLI)+AllTrim(TRBF->LOJA),"A1_NOME") ,;  // 09
			IIf(TRBF->TPCAR == 'A','AGENDADA',If(TRBF->TPCAR = 'I','IMEDIATA',If(TRBF->TPCAR = 'O','AGENDADA P/ O.LOG.',IIf(TRBF->TPCAR == 'M','AGENDADA C/MULTA','AGUARD. AGENDA')))) ,;// 10
			AllTrim(TRBF->DTEMISS),;                        // 11
			AllTrim(DToC(ctod(TRBF->DT_ENTREG)-_ndias)),;   // 12
			StrZero(_ndias,3) ,;                            // 13
			AllTrim(TRBF->DT_ENTREG),;                      // 14
			IIf(TRBF->TPFRETE=="C",'CIF','FOB') ,;          // 15
			TRBF->TAB_PREC + " - "  + AllTrim(Posicione("DA0",1,xFilial("DA0")+TRBF->TAB_PREC ,"DA0_DESCRI")),;  // 16
			TRBF->CONDPAGTO + " - " + AllTrim(Posicione("SE4",1,xFilial("SE4")+TRBF->CONDPAGTO,"E4_DESCRI")) ,;  // 17
			TRBF->VEND1 + " - " + AllTrim(Posicione("SA3",1,xFilial("SA3")+TRBF->VEND1,"A3_NREDUZ")) ,;          // 18
			AllTrim(TRBF->MENSANF) ,;                        // 19
			AllTrim(TRBF->OBSCOMER),;                        // 20
			TRBF->(Recno()),;                                // 21
			TRBF->STATUS1,;                                  // 22
			TRBF->STATUS2,;                                  // 23
			TRBF->STATUS3,;                                  // 24
			TRBF->VALOR,;                                    // 25
			TRBF->OPTRI,;                                    // 26
			_cliremessa,;                                    // 27
			_cTempoPend,;									 // 28
			TRBF->PESO,;                                     // 29
			TRBF->DESCONTO,;								 // 30
			TRBF->NMMVEND2,;								 // 31
			TRBF->NMVEND3})									 // 32
		Else// AO TROCAR AS ORDENS DOS CAMPOS NA TELA: TROQUE A ORDEM AQUI TB E TESTE VIA HTML "ACERTO MANUAL"
			aAdd(aarr,{	_cok,;            // 01
			"  ",;                        // 02
			"  ",;                        // 03
			AllTrim(TRBF->IMPRIME),;      // 04
			AllTrim(TRBF->DTEMISS),;      // 05
			_cTempoPend,;				  // 06
			IIf(TRBF->TPCAR='A','AGENDADA',If(TRBF->TPCAR='I','IMEDIATA',If(TRBF->TPCAR='O','AGENDADA P/ O.LOG.',IIf(TRBF->TPCAR='M','AGENDADA C/MULTA','AGUARD. AGENDA')))) ,;// 07
			AllTrim(TRBF->DT_ENTREG),;    // 08
			AllTrim(TRBF->FILIAL) ,;      // 09
			TRBF->FILPRO ,;               // 10
			TRBF->CONDPAGTO + " - " + AllTrim(Posicione("SE4",1,xFilial("SE4")+TRBF->CONDPAGTO,"E4_DESCRI")) ,; // 11
			AllTrim(TRBF->NUMPED) ,;                                                                            // 12
			TRBF->TIPO + " - " + SubStr(Posicione("ZB4",1,xFilial("ZB4")+TRBF->TIPO,"ZB4_DESCRI"),1,20),;       // 13
			_cliremessa,;                                                                                       // 14
			AllTrim(TRBF->CODCLI) + "/" + AllTrim(TRBF->LOJA) + " - " + Posicione("SA1",1,xFilial("SA1")+AllTrim(TRBF->CODCLI)+AllTrim(TRBF->LOJA),"A1_NOME") ,;  // 15
			TRBF->VALOR,;                                // 16
			IIf(TRBF->TPFRETE=="C",'CIF','FOB') ,;       // 17
			TRBF->PESO,;                                 // 18
			TRBF->DESCONTO,;			                 // 19
			AllTrim(TRBF->OBSCOMER),;                    // 20
			AllTrim(TRBF->MENSANF) ,;                    // 21
			StrZero(_ndias,3) ,;                         // 22
			AllTrim(DToC(ctod(TRBF->DT_ENTREG)-_ndias)),;// 23
			TRBF->TAB_PREC + " - " +  AllTrim(Posicione("DA0",1,xFilial("DA0")+TRBF->TAB_PREC,"DA0_DESCRI")),;  // 24
			TRBF->VEND1 + " - " + AllTrim(Posicione("SA3",1,xFilial("SA3")+TRBF->VEND1,"A3_NREDUZ")) ,;         // 25
			TRBF->NMMVEND2,;			  // 26
			TRBF->NMVEND3,;			      // 27
			TRBF->OPTRI,;                 // 28
			TRBF->STATUS3,;               // 29
			TRBF->STATUS2,;               // 30
			TRBF->STATUS1,;               // 31
			TRBF->(Recno())})	          // 32 <-- Garantir que o recno fique sempre na ultima posição no html
		EndIf
	EndIf
	TRB->( DBSkip() )
EndDo

TRB->( DBCloseArea())

TRBF->(DBGoTop())

If _lcabec  //Inicializa cabecalho

	If MV_PAR23 <> 1 //DE SÓ REJEITADOS
		nQtdTit := 0
	EndIf
	nPesTit	:= 0
	nValTit := 0

	oQtda:Refresh()
	oValor:Refresh()

EndIf

//Se browse já está montando garante que array está atualizado
If Type("omark") == "O" 
	If nQtdRegs > 0 .And. Len(aarr) > 0
		If !lHtml//QUANDO For HTML O ARRAY DEVE SER ORDENADO MANUALMENTE
			A112RA()////REORDENA O AARR PARA PERMITIR AS MODIFICAÇOES NAS COLUNAS
		EndIf
		omark:setarray(aarr)
		omark:refresh()
		TRBF->(DBGoTo(aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]))
	Else
		aarr := {}
		omark:setarray(aarr)
		omark:refresh()
		U_ITMsg("Não há registros para o filtro atual.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS112()
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/10/2018
Descrição---------: Chamada de itens do menu
Parametros--------: _nopc - Opção do menu
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112C(_nopc)

Local oproc

If Len(aarr) > 0
	TRBF->(DBGoTo(aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]))
EndIf

Do Case

	Case _nopc == 1
		//Atualizar
		FWMsgRun(,{ |oproc| AOMS112arq(oproc) }, "Aguarde...","Carregando dados...")

	Case _nopc == 2
		//Pesquisa
		If Len(aarr) > 0
			AOMS112PSQ()
		Else
			U_ITMsg("Não há registros para pesquisar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
		EndIf

	Case _nopc == 3
		//Filtro
		FWMsgRun(,{ |oproc| AOMS112FIL(oproc) }, "Aguarde...","Carregando dados...")

	Case _nopc == 4
		//Altera filiais
		If Len(aarr) > 0
			FWMsgRun(,{ |oproc| AOMS112AF() }, "Aguarde...","Carregando dados...")
		Else
			U_ITMsg("Não há registros para alterar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
		EndIf

	Case _nopc == 5
		//Visualizar Pedido
		If Len(aarr) > 0
			FWMsgRun(,{ || AOMS112VP() }, "Aguarde...","Carregando dados...")
		Else
			U_ITMsg("Não há registros para visualizar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
		EndIf

	Case _nopc == 6
		//Alterar
		If Len(aarr) > 0
			FWMsgRun(,{ || AOMS112AT() }, "Aguarde...","Carregando dados...")
		Else
			U_ITMsg("Não há registros para alterar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
		EndIf

	Case _nopc == 7
		//Legenda
		AOMS112LEG()

	Case _nopc == 8
		//Marcar não impresso
		If Len(aarr) > 0
			FWMsgRun(,{ |oproc| AOMS112DI(oproc) }, "Aguarde...","Carregando dados...")
		Else
			U_ITMsg("Não há registros para marcar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
		EndIf

	Case _nopc == 9
		//Recusar
		If Len(aarr) > 0
			FWMsgRun(,{ |oproc| AOMS112REC(oproc) }, "Aguarde...","Carregando dados...")
		Else
			U_ITMsg("Não há registros para recusar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
		EndIf

	Case _nopc == 10
		//Exporta Excel
		If Len(aarr) > 0
			FWMsgRun(,{ || AOMS112EC(oproc) }, "Aguarde...","Carregando dados...")
		Else
			U_ITMsg("Não há registros para exportar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
		EndIf

	Case _nopc == 11
		//Efetivar
		If Len(aarr) > 0
			FWMsgRun(,{ || AOMS112EFI(oproc) }, "Aguarde...","Carregando dados...")
		Else
			U_ITMsg("Não há registros para efetivar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
		EndIf

	Case _nopc == 12
		//Imprimir
		If Len(aarr) > 0
			FWMsgRun(,{ |oproc| AOMS112IM(oproc) }, "Aguarde...","Carregando dados...")
		Else
			U_ITMsg("Não há registros para imprimir.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
		EndIf

	OtherWise
		U_ITMsg("Opção não existe","Atenção","Contate a area de TI",1)
EndCase

If Len(aarr) > 0
	TRBF->(DBGoTo(aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]))
EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS1129
Autor-----------: Josué Danich Prestes
Data da Criacao-: 18/02/2014
Descrição-------: Retorna cor e legenda
Parametros------: _nLinha - linha a ser posicionada
									_lsimples - retorno simplificado para filtro
Retorno---------: string com cor da legenda da linha posicionada no TRBF
===============================================================================================================================
*/
User Function AOMS1129(_nLinha,_lsimples,lweb)

Local _ccor := "BR_VERMELHO"
Local _ncor := 11
Local lHtml:= (GetRemoteType() == 5)
Default _lsimples := .F.
Default lweb := .F.
Default _nLinha := aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]

If ValType(_nLinha) == "C" .And. lHtml
	_nLinha := OMARK:NAT
EndIf

Begin Sequence

	TRBF->(DBGoTo(_nLinha))

	If MV_PAR23 = 1 //SÓ REJEITADOS

		_ccor := "UPDERROR"//"QMT_NO"//"UPDERROR"
		_ncor := 12

	ElseIf TRBF->BLQLCR == 'R'

		_ccor := "BR_LARANJA"
		_ncor := 1

	ElseIf TRBF->BLOPRC == 'B' .And. AllTrim(TRBF->ENVWF) == 'C'

		_ccor := "BR_AMARELO"
		_ncor := 9

	ElseIf TRBF->BLOPRC == 'B' .And. AllTrim(TRBF->ENVWF) == 'G'
		_ccor := "BR_VERDE_ESCURO"
		_ncor := 10

	ElseIf TRBF->STAT_ZW == 'L' .And. Empty(AllTrim(TRBF->ENVWF))
		_ccor := "BR_VERDE_ESCURO"
		_ncor := 10

	ElseIf TRBF->BLOCLI == '1'

		_ccor := "BR_CANCEL"
		_ncor := 2

	ElseIf TRBF->TIPO = '10' .And. TRBF->BLOQ != 'L' .And. TRBF->BLOQ != 'R'

		_ccor := "BR_MARRON_OCEAN
		_ncor := 3

	ElseIf TRBF->TIPO = '10' .And.  TRBF->BLOQ == 'R'

		_ccor := "BR_MARRON"
		_ncor := 4

	ElseIf ( TRBF->BLQLCR == 'C' .Or. TRBF->BLQLCR == 'L' .Or. Empty(TRBF->BLQLCR) ) .And. TRBF->BLOPRC == 'R'

		_ccor := "BR_VIOLETA"
		_ncor := 5

	ElseIf ( TRBF->BLQLCR == 'C' .Or. TRBF->BLQLCR == 'L' .Or. Empty(TRBF->BLQLCR) ) .And. TRBF->BLOPRC == 'B'

		_ccor := "BR_PRETO"
		_ncor := 6

	ElseIf ( TRBF->BLQLCR == 'C' .Or. TRBF->BLQLCR == 'L' .Or. Empty(TRBF->BLQLCR) ) .And. TRBF->BLOPRC == 'L'

		_ccor := "BR_VERDE"
		_ncor := 7

	ElseIf TRBF->BLQLCR == 'B'

		_ccor := "BR_AZUL"
		_ncor := 8

	Else

		_ccor := "BR_VERMELHO"
		_ncor := 11

	EndIf

End Sequence

If lweb
	_ccor := SubStr(_ccor,4)
EndIf
If _lsimples
	_xret := {}
	aAdd(_xret,_ncor)
	aAdd(_xret,_ccor)
Else
	_xret := _ccor
EndIf

Return _xret

/*
===============================================================================================================================
Programa--------: AOMS1128
Autor-----------: Josué Danich Prestes
Data da Criacao-: 18/02/2014
Descrição-------: Retorna cor e legenda para simulador
Parametros------: _nLinha - linha do browse
Retorno---------: string com cor da legenda da linha posicionada no TRBF
===============================================================================================================================
*/
User Function AOMS1128(_nLinha,lweb)

Local _ccor := "BR_BRANCO"
Local cRet
Local aArea  := FWGetArea()
Local lHtml:= (GetRemoteType() == 5)

Default _nLinha := aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]

MV_PAR06 := 2 //DESABILITAR SIMULADOR por garantia aqui tb

If ValType(_nLinha) == "C" .And. lHtml
	_nLinha := OMARK:NAT
EndIf

TRBF->(DBGoTo(_nLinha))

If MV_PAR06 == 2

	//Legenda em branco sem simulador de preços
	_ccor := "BPMTASK3"

	Return cret

EndIf

If TRBF->BLOCLI == '1'

	_ccor := "VERMELHO"

ElseIf TRBF->TIPO = '10' .And. TRBF->BLOQ != 'L'

	_ccor := "VERMELHO"

Else

	_ccor := "VERDE"

	//Valida preço para o pedido
	SZW->(DBSetOrder(1))
	If SZW->(DBSeek(SubStr(TRBF->FILIAL,1,2)+TRBF->NUMPED))


		While SZW->ZW_FILIAL == SubStr(TRBF->FILIAL,1,2) .And. SZW->ZW_IDPED == TRBF->NUMPED

			If SZW->ZW_BLOPRC == "B"
				_ccor := "VERMELHO"
				Exit
			EndIf

			SZW->(DBSkip())
		EndDo
	EndIf
EndIf

FWRestArea(aArea)

Return _ccor

/*
===============================================================================================================================
Programa----------: AOMS112FIL
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Função que refaz filtro da tela
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112FIL(oproc)

If Pergunte( cPerg , .T. )
	// Cria o arquivo Temporario para insercao dos dados selecionados.
	FWMsgRun( , {|oproc| AOMS112ARQ(oproc) }, "Aguarde!" , 'Lendo Dados dos pedidos...' )
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS112PSQ
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Funcao para pesquisa no arquivo temporario.
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112PSQ( oproc)

Local oGet1		:= Nil
Local oDlg		:= Nil
Local cGet1		:= Space(40)
Local cComboBx1	:= ""
Local aComboBx1	:= { "Pedido" , "Cliente/Remessa" , "Nome Cliente/Remessa" , "Nome Rede" }
Local nOpca		:= 0
Local nI		:= 0

DEFINE MSDIALOG oDlg TITLE "Pesquisar" FROM 178,181 TO 259,697 PIXEL

@004,003 ComboBox	cComboBx1	Items aComboBx1 Size 213,010 OF oDlg PIXEL
@020,003 MsGet		oGet1		Var cGet1		Size 212,009 OF oDlg PIXEL COLOR CLR_BLACK Picture "@!"

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( nOpca := 1 , oDlg:End() ) OF oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( nOpca := 0 , oDlg:End() ) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1

	For nI := 1 To Len(aComboBx1)

		If cComboBx1 == aComboBx1[nI]

			DBSelectArea("TRBF")
			TRBF->( DBSetOrder(ni) )

			If TRBF->(DBSeek( cGet1 ))

				_npos := aScan(aarr,{|x| x[Len(x)] = TRBF->(Recno())})
				oMark:Goposition(_npos)
				oMark:Refresh()

			Else
				U_ITMsg(cComboBx1+" não encontrado!")
			EndIf

			TRBF->( DBSetOrder(1) )

		EndIf

	Next nI

EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS112VP
Autor-------------: Erich Buttner
Data da Criacao---: 12/03/2013
Descrição---------: Rotina para VISUALIZAÇÃO DOS PEDIDOS
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112VP()

Local cTitulo	 := "Visualização de Pedido Portal"
Local lRetMod2 	 := .F. // Retorno da função Modelo2 - .T. Confirmou / .F. Cancelou
Local nLinha	 := 0,nColuna
Local _cRede     := "999999"
Local _cUFCli    := ""
Local _lSimplNac := .F.
Local _nPesoBrutoPedido := 0
Local _aBlqprc := {}

Public nOpcx	 := 7

DBSelectArea("Sx3")
SX3->( DBSetOrder(1) )
SX3->( DBSeek("SZW") )

nUsado		:= 0
aHeader		:= {}
aCols		:= {}
cDescr		:= ""
nQtd2UM		:= 0
c2UM		:= ""
nVlrTot		:= 0
nVTot		:= 0

// Montagem do aHeader
If MV_PAR06 == 1 //Simulador

	aHeader := {{ "Item"			, "ZW_ITEM"		    , "@!"						,010,0,"AllwaysTrue()","","C","","R"},;
				{ "Produto"			, "ZW_PRODUTO"	    , "@!"						,015,0,"AllwaysTrue()","","C","","R"},;
				{ "Descrição"		, "cDescr"			, "@!"						,020,0,"AllwaysTrue()","","C","","R"},;
				{ "Qtd Ven 2 UM"	, "nQtd2UM"		    , "@e 999,999,999.99"	    ,014,2,"AllwaysTrue()","","C","","R"},;
				{ "Segunda UM"		, "c2UM"			, "@!"						,002,0,"AllwaysTrue()","","C","","R"},;
				{ "Quantidade"		, "ZW_QTDVEN"		, "@e 999,999,999.99"	    ,014,2,"AllwaysTrue()","","C","","R"},;
				{ "Unidade"			, "ZW_UM"			, "@!"						,002,0,"AllwaysTrue()","","C","","R"},;
				{ "Prc Unitario"	, "ZW_PRCVEN"		, "@e 9,999,999.9999"	    ,014,4,"AllwaysTrue()","","C","","R"},;
				{ "Preco Net"		, "ZW_I_PRNET"      , "@e 9,999,999.9999"	    ,014,4,"AllwaysTrue()","","C","","R"},;
				{ "Vlr.Total "		, "nVlrTot"		    , "@e 999,999,999.99"	    ,014,2,"AllwaysTrue()","","C","","R"},;
				{ "Blq. Preço "		, "ZW_BLOPRC"		, "@!"						,001,0,"AllwaysTrue()","","C","","R"},;
				{ "Tab Preço "	    , "ZW_TABELA + ' - ' + Posicione('DA0',1,xFilial('DA0')+ZW_TABELA,'DA0_DESCRI')", "@!", 004 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
				{ "Sit Preço "	    , "csituaca"	    , "@!"						, 020 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
				{ "Sel Tabela "	    , " "	            , "@!"						, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
				{ "Reg Regra "	    , " "	            , "@99999999"				, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
				{ "Local "		    , "ZW_LOCAL"	    , "@!"						, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" } }

Else

	aHeader := {{ "Item"		    , "ZW_ITEM"		      ,"@!"						,010,0,"AllwaysTrue()","","C","","R"},;
				{ "Produto"			, "ZW_PRODUTO"	      ,"@!"						,015,0,"AllwaysTrue()","","C","","R"},;
				{ "Descrição"		, "cDescr"			  ,"@!"						,020,0,"AllwaysTrue()","","C","","R"},;
				{ "Qtd Ven 2 UM"	, "nQtd2UM"		      ,"@e 999,999,999.99"	    ,014,2,"AllwaysTrue()","","C","","R"},;
				{ "Segunda UM"		, "c2UM"			  ,"@!"						,002,0,"AllwaysTrue()","","C","","R"},;
				{ "Quantidade"		, "ZW_QTDVEN"		  ,"@e 999,999,999.99"	    ,014,2,"AllwaysTrue()","","C","","R"},;
				{ "Unidade"			, "ZW_UM"			  ,"@!"						,002,0,"AllwaysTrue()","","C","","R"},;
				{ "Prc Unitario"	, "ZW_PRCVEN"		  ,"@e 9,999,999.9999"	    ,014,4,"AllwaysTrue()","","C","","R"},;
				{ "Preco Net "	    , "ZW_I_PRNET"        ,"@e 9,999,999.9999"	    ,014,4,"AllwaysTrue()","","C","","R"},;
				{ "Vlr.Total "		, "nVlrTot"		      ,"@e 999,999,999.99"	    ,014,2,"AllwaysTrue()","","C","","R"},;
				{ "Blq. Preço "		, "ZW_BLOPRC"		  ,"@!"						,001,0,"AllwaysTrue()","","C","","R"},;
				{ "Local "		    , "ZW_LOCAL"	      ,"@!"						,002,0,"AllwaysTrue()","","C","","R"} }

EndIf


_nPesoBrutoPedido := AOMS112PES(TRBF->FILIAL,TRBF->NUMPED)

DBSelectArea("SZW")
SZW->( DBSetOrder(1) )
SZW->( DBSeek( SubStr( TRBF->FILIAL , 1 , 2 ) + TRBF->NUMPED ) )
While SZW->( !Eof() ) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == SubStr( TRBF->FILIAL , 1 , 2 ) + TRBF->NUMPED

	// Montagem do Acols
	aAdd( aCols , Array( Len(aHeader) + 1 ) )
	nLinha++


	cDescr      := Posicione('SB1',1,xFilial("SB1")+AllTrim(SZW->ZW_PRODUTO),'B1_DESC')
	nFatConv	:= SB1->B1_CONV
	cTpConv		:= SB1->B1_TIPCONV
	nNewFat		:= SB1->B1_I_FATCO
	c2UM		:= SB1->B1_SEGUM
	cGrupoP		:= SB1->B1_GRUPO


	If SZW->ZW_FILPRO != '0 ' .And. !Empty(SZW->ZW_FILPRO) .And. SZW->ZW_FILPRO != SZW->ZW_FILIAL

		_cfilpro := SZW->ZW_FILPRO

	Else

		_cfilpro := SZW->ZW_FILIAL

	EndIf
	_cRede  := Posicione('SA1',1,xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,'A1_GRPVEN')
	_cUFCli := SA1->A1_EST

	_lSimplNac  :=If(SA1->A1_SIMPNAC="1",.T.,.F.)

	_csuper := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_I_SUPE")
	_cCoord := SA3->A3_SUPER
	_cGeren := SA3->A3_GEREN

	//Posiciona a tabela de preço e verifica se preço está ok
	DA1->(DBSetOrder(1))
	If !DA1->(DBSeek(xFilial("DA1")+SZW->ZW_TABELA+SZW->ZW_PRODUTO))

		csituaca := "Produto não consta na tabela de preço"

	ElseIf SZW->ZW_PRCVEN > DA1->DA1_PRCMAX

		csituaca    := "Preço acima do máximo: " + transform(DA1->DA1_PRCMAX,"@E 999,999,999.99")

	ElseIf Round(SZW->ZW_PRCVEN,2) < DA1->DA1_I_PMF3 .And. SZW->ZW_KIT == ' ' 

		//Valida pela função padrão para pegar exceções
		_chistprec := "  "
		_aBlqprc := U_BLQPRC(SZW->ZW_PRODUTO,SZW->ZW_PRCVEN,SZW->ZW_FILIAL,   .F.,SZW->ZW_TABELA,    .T.,      .T.,        .T.,           ,  cGrupoP, _cUFCli,         ,SZW->ZW_TPVENDA,_lSimplNac,_nPesoBrutoPedido,SZW->ZW_I_FXPES)

		_lbloq   := _aBlqprc[1]

		If !_lbloq

			csituaca := "Pré Aprovado - " + _chistprec

		Else

			csituaca := "Preço abaixo do mínimo: " + transform(DA1->DA1_I_PMF3,"@E 999,999,999.99")

		EndIf

	Else

		csituaca    := "Pré Aprovado"

	EndIf

	If cTpConv == "M"
		nQtd2UM	:= IIf( nFatConv == 0 , nNewFat * SZW->ZW_QTDVEN	, nFatConv * SZW->ZW_QTDVEN	)
	Else
		nQtd2UM	:= IIf( nFatConv == 0 , SZW->ZW_QTDVEN / nNewFat	, SZW->ZW_QTDVEN / nFatConv	)
	EndIf

	nVlrTot		:= SZW->ZW_QTDVEN * SZW->ZW_PRCVEN
	nVtot		+= nVlrTot

	For nColuna := 1 to Len(aHeader)
		aCols[nLinha][nColuna] := &( aHeader[nColuna][2] )
	Next nColuna

	aCols[nLinha][Len(aHeader)+1] := .F. // Linha não deletada

	SZW->( DBSkip() )

EndDo

cFli		:= Space(20)
cFilPro		:= Space(40)
cTipPed		:= Space(15)
cNumPed		:= Space(25)
cCliente	:= Space(06)
cNomCli		:= Space(60)
cLojaCli	:= Space(04)
cGrpCli		:= Space(30)
cCond		:= Space(50)
cVend1		:= Space(06)
cTabelaPrc	:= Space(06)
cDescTabela	:= Space(40)
cPedCli		:= Space(09)
dDtEnt		:= CtoD("")
cTipoAg		:= Space(10)
cHrEnt		:= Space(05)
cSha		:= Space(14)
cTipFre		:= Space(10)
cClassEnt	:= Space(20)
cTipCar		:= Space(15)
cQtdCha		:= Space(03)
cHrDes		:= Space(05)
nCusDes		:= 0
cObsCom		:= Space(300)
cObsNF		:= Space(300)
cObsALC		:= Space(300)
cMotRec		:= Space(300)

DBSelectArea("SZW")
SZW->( DBSetOrder(1) )
SZW->( DBSeek( SubStr( TRBF->FILIAL , 1 , 2 ) + TRBF->NUMPED ) )

dDtEnt		:= SZW->ZW_FECENT
_laltera := .T.

If SZW->ZW_I_AGEND == 'P'
	If month(date()) != 12
		dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+1)))+"0101")-1
	Else
		dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+2)))+"0101")-1
	EndIf
	_laltera := .F.
EndIf

If SZW->ZW_I_AGEND $ 'I/O'//I=Imediata //O=Agendada pelo Op.Log.

	_cFilCarreg := SZW->ZW_FILIAL
	If !Empty(SZW->ZW_FILPRO) .And. !(AllTrim(SZW->ZW_FILPRO)=='0')
		_cFilCarreg := SZW->ZW_FILPRO
	EndIf

	//cTipoAg		:= SZW->ZW_I_AGEND+" - IMEDIATO"
	dDtEnt := DATE()+u_omsvldent(DATE(),SZW->ZW_CLIENTE,SZW->ZW_LOJACLI,SZW->ZW_FILIAL,TRBF->NUMPED,1,.F.,_cFilCarreg,SZW->ZW_TIPO,SZW->ZW_TPVENDA)
	_laltera := .F.

EndIf

cTipoAg:=SZW->ZW_I_AGEND+" - "+(U_TipoEntrega(SZW->ZW_I_AGEND))

// Configuracao dos Campos
// aC[n,1] = Nome da Variavel Ex.:"cCliente"
// aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
// aC[n,3] = Titulo do Campo
// aC[n,4] = Picture
// aC[n,5] = Validacao
// aC[n,6] = F3
// aC[n,7] = Se campo e' editavel .T. se nao .F.
aC := {	{ "cFli"	, {015,003}	, "Filial                   " 	  	,"@!"   				,	,		,.F.	},;
	{ "cFilPro" 	, {015,203} , "Filial Carregamento   "         	,"@!"   				,   ,       ,.F.	},;
	{ "cTipPed"		, {030,003}	, "Tipo Pedido       " 				,"@!"   				,	,		,.F.	},;
	{ "cNumPed"		, {030,203}	, "Num. Pedido           " 			,"@!"   				,	,		,.F.	},;
	{ "cCliente"  	, {045,003}	, "Cliente/Remessa" 				,"@!"   				,	,		,.F.	},;
	{ "cLojaCli"	, {045,085}	, "Loja   "							,"@!"   				,	,		,.F.	},;
	{ "cNomCli"		, {045,140}	, "Nome Cliente/Remessa"			,"@!"   				,	,		,.F.	},;
	{ "cGrpCli"		, {060,003}	, "Grupo Cliente/Rem."				,"@!"   				,	,		,.F.	},;
	{ "cCond"		, {060,285}	, "Cond. Pagto" 					,"@!"   				,	,		,.F.	},;
	{ "cVend1"		, {075,003}	, "Vendedor 1       "  				,"@!"   				,	,		,.F.	},;
	{ "cNmVend1"	, {075,140}	, "Nome Vendedor 1" 				,"@!"   				,	,		,.F.	},;
	{ "nVTot"		, {075,500}	, "Valor Total   " 					,"@e 999,999,999.99"	,	,		,.F.	},;
	{ "cTabelaPrc"  , {090,003}	, "Cod.Tab.Prc       "  			,"@!"   				,	,		,.F.	},;
	{ "cDescTabela"	, {090,140}	, "Desc. Tabela   " 				,"@!"   				,	,		,.F.	},;
	{ "cPedCli"		, {105,003}	, "Pedido Cliente/Remessa"		    ,"@!"   				,	,		,.F.	},;
	{ "dDtEnt"		, {015,500}	, "Data Entrega          "			,"@!"   				,	,		,_laltera	},;
	{ "cTipoAg"		, {030,500}	, "Tipo Agendamento"				,"@!"   				,	,		,.F.	},;
	{ "cHrEnt"		, {105,245}	, "Hora Entrega   "					,"@!"   				,	,		,.F.	},;
	{ "cSha"		, {105,325}	, "Senha                "			,"@!"   				,	,		,.F.	},;
	{ "cTipFre"		, {105,500}	, "Tipo Frete    "					,"@!"   				,	,		,.F.	},;
	{ "cTipCar"		, {120,003}	, "Tipo de Carga     "				,"@!"   				,	,		,.F.	},;
	{ "cQtdCha"		, {120,140}	, "Qtd. Chapa"          			,"@!"   				,	,		,.F.	},;
	{ "cHrDes"		, {120,245}	, "Hora Descarga"					,"@!"   				,	,		,.F.	},;
	{ "nCusDes"		, {120,325}	, "Custo Descarga"					,"@e 999,999,999.99"	,	,		,.F.	},;
	{ "cClassEnt"   , {120,500}	, "Classif. Entrega"				,"@!"   				,	,		,.F.	},;
	{ "cObsCom"		, {135,003}	, "Obs. Comercial  "				,"@!"					,	,		,.F.	},;
	{ "cObsNf"		, {150,003}	, "Mensagem NF    "					,"@!"					,	,		,.F.	},;
	{ "cObsALC"		, {165,003}	, "Análise Lim. Cr. "				,"@!"					,	,		,.F.	} }
	_nLinha:=165
	_nLinha+=15
	aAdd(aC,{ "cMotRec",{_nLinha,003},"Motivo da Recusa"	  		     ,"@!",,,.F.})
	_nLinha+=15
	aAdd(aC,{ "_cGData",{_nLinha,003},"Data de Aprovação do Gerente"     ,"@D",,,.F.})
	aAdd(aC,{ "_cCData",{_nLinha,203},"Data de Aprovação do Coordenador" ,"@D",,,.F.})
	_nLinha+=15
	aAdd(aC,{ "_cGHora",{_nLinha,003},"Hora de Aprovação do Gerente"     ,"@!",,,.F.})
	aAdd(aC,{ "_cCHora",{_nLinha,203},"Hora de Aprovação do Coordenador" ,"@!",,,.F.})

// Conteudo dos Campos
// aR[n,1] = Nome da Variavel Ex.:"cCliente"
// aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
// aR[n,3] = Titulo do Campo
// aR[n,4] = Picture
// aR[n,5] = Validacao
// aR[n,6] = F3
// aR[n,7] = Se campo e' editavel .T. se nao .F.

aR := {}
DBSelectArea("SZW")
SZW->( DBSetOrder (1) )
If SZW->( DBSeek( SubStr( TRBF->FILIAL , 1 , 2 ) + TRBF->NUMPED ) )

	cClassEnt:=Posicione("SA1",1,xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,"A1_I_CLABC")
	If cClassEnt = '1'
		cClassEnt:="1-TOP 1 NACIONAL"
	ElseIf cClassEnt = '2'
		cClassEnt:="2-TOP 5 Reg. SP"
	ElseIf cClassEnt = '3'
		cClassEnt:="3-TOP 5 Reg. RS"
	EndIf

	cFli		:= LEFT(SubStr(TRBF->FILIAL,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(TRBF->FILIAL,1,2),1,""),25)
	cFilPro		:= SubStr(TRBF->FILPRO,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(TRBF->FILPRO,1,2),1,"")
	cTipPed		:= SubStr(TRBF->TIPO+" - "+GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+TRBF->TIPO,1,""),1,25)
	cNumPed  	:= TRBF->NUMPED
	cCliente 	:= SZW->ZW_CLIENTE
	cLojaCli 	:= SZW->ZW_LOJACLI
	cNomCli 	:= GetAdvFVal("SA1","A1_NOME",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")
	cGrpCli		:= GetAdvFVal("SA1","A1_GRPVEN",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")+" - "+GetAdvFVal("SA1","A1_I_NGRPC",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")
	cVend1	 	:= SZW->ZW_VEND1
	cNmVend1 	:= GetAdvFVal("SA3","A3_NOME",xFilial("SA3")+SZW->ZW_VEND1,1,"")
	cTabelaPrc  := SZW->ZW_TABELA
	cDescTabela := GetAdvFVal("DA0","DA0_DESCRI",xFilial("DA0")+SZW->ZW_TABELA,1,"")
	nVTot 		:= nVTot
	cPedCli		:= SZW->ZW_PEDCLI
	ccond       := SZW->ZW_CONDPAG
	cHrEnt		:= SZW->ZW_HOREN
	cSha		:= SZW->ZW_SENHA
	cTipFre		:= If(SZW->ZW_TPFRETE == 'C',SZW->ZW_TPFRETE+" - CIF",SZW->ZW_TPFRETE+" - FOB")
	_cchep 		:= Posicione("SA1",1,xFilial("SA1")+ccliente+cLojaCli,"A1_I_CCHEP")
	cTipCar		:= If( !Empty(_cchep) , "1 - Paletizada" , "2 - Batida" )
	cQtdCha		:= SZW->ZW_CHAPA
	cHrDes		:= SZW->ZW_HORDES
	nCusDes		:= SZW->ZW_CUSDES
	cObsCom		:= SZW->ZW_OBSCOM
	cObsNF		:= SZW->ZW_MENNOTA
	cObsALC		:= SZW->ZW_OBSAVAC
	cMotRec	    := AllTrim(SZW->ZW_MOTREC)
	cMotRec	    := cMotRec+Space(200-Len(cMotRec))
	_cGData     := SZW->ZW_I_DLIBG
	_cGHora     := SZW->ZW_I_HLIBG
	_cCData     := SZW->ZW_DATAAPR 
	_cCHora     := SZW->ZW_HORAAPR 

	// Array com as Coordenadas da Tela para o GetDados
	aCGD:={350,06,26,74}

	// Chamada da Modelo2
	lRetMod2 := Modelo2( cTitulo , aC , aR , aCGD , nOpcx ,,,,,, 9999 ,,, .T. )
Else
	U_ITMsg(  'Não foi possível posicionar no pedido!' , 'Atenção!',,1)
EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS1125
Autor-----------: Josué Danich Prestes
Data da Criacao-: 28/03/2018
Descrição-------: Retorna condição de pagamento do pedido de vendas
Parametros------: Nenhum
Retorno---------: _ccond - Condição de pagamento do pedido de vendas
===============================================================================================================================
*/
Static Function AOMS1125()

Local _ccond := ""

M->C5_CONDPAG:=SZW->ZW_CONDPAG//USA ESSA VARIAVEL DENTRO DA FUNÇÃO u_IT_conpg()
_ccond := u_IT_conpg(AllTrim(SZW->ZW_CLIENTE),AllTrim(SZW->ZW_LOJACLI),AllTrim(SZW->ZW_PRODUTO),.F.)
//Se achou regra de condição de pagamento usa a regra, senão achou regra pega do szw
If !Empty(_ccond)
	_cCond:=_ccond+" - "+GetAdvFVal("SE4","E4_DESCRI",xFilial("SE4")+_ccond,1,"")
Else
	_cCond:=SZW->ZW_CONDPAG+" - "+GetAdvFVal("SE4","E4_DESCRI",xFilial("SE4")+SZW->ZW_CONDPAG,1,"")
EndIf

Return _ccond

/*
===============================================================================================================================
Programa--------: AOMS112AT
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Função de alteração do Tp de pedido antes da efetivação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112AT()

Local cTitulo	:= "Alterar Pedidos Portal"
Local lRetMod2  := .F. // Retorno da função Modelo2 - .T. Confirmou / .F. Cancelou
Local nLinha	:= 0
Local _nI , nColuna
Local lMuda		:= .F.
Local lFrete	:= .F.

Private _nPosLocal, _nPosProd, _nPosItem

nUsado	:= 0
aHeader	:= {}
aCols	:= {}
cDescr	:= ""
nQtd2UM	:= 0
c2UM	:= ""
nVlrTot	:= 0
nVTot	:= 0

_aButtons := {}
aAdd(_aButtons,{"Alt.Armazem",{|| U_AOMS112B(N,_nPosLocal,_nPosProd) },"Altera Armazem","Altera Armazem"})

// Montagem do aHeader
aHeader := {{ "Item"		  	, "ZW_ITEM"		, "@!"						, 010 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Produto"	  		, "ZW_PRODUTO"	, "@!"						, 015 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Descrição"	  	, "cDescr" 		, "@!"						, 020 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Qtd Ven 2 UM"  	, "nQtd2UM"		, "@e 999,999,999.99"	    , 014 , 2 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Segunda UM"	   	, "c2UM"		, "@!"						, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Quantidade"		, "ZW_QTDVEN"	, "@e 999,999,999.99"	    , 014 , 2 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Unidade"		   	, "ZW_UM"		, "@!"						, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Prc Unitario" 	, "ZW_PRCVEN"	, "@e 9,999,999.9999"	    , 014 , 4 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Vlr.Total "		, "nVlrTot"		, "@e 999,999,999.99"	    , 014 , 2 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Blq. Preço "		, "ZW_BLOPRC"	, "@!"						, 001 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
			{ "Local "		    , "ZW_LOCAL"	, "@!"						, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" } }

cFlVer := SubStr( TRBF->FILIAL , 1 , 2 )

_nPosLocal := aScan(aHeader,{|x| x[2] = "ZW_LOCAL"})
_nPosProd  := aScan(aHeader,{|x| x[2] = "ZW_PRODUTO"})
_nPosItem  := aScan(aHeader,{|x| x[2] = "ZW_ITEM"})

//Locka registros
If !( AOMS112LO( cFlVer, TRBF->NUMPED ) )
	Return
EndIf

DBSelectArea("SZW")
SZW->( DBSetOrder(1) )
If SZW->( DBSeek( cFlVer + TRBF->NUMPED ) )

	// Montagem do aCols
	While SZW->( !Eof() ) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == cFlVer + TRBF->NUMPED

		aAdd( aCols , Array( Len(aHeader) + 1 ) )
		nLinha++

		cDescr		:= GetAdvFVal( "SB1" , "B1_I_DESCD"	, xFilial("SB1") + AllTrim( SZW->ZW_PRODUTO )	, 1 , "" )
		nFatConv	:= GetAdvFVal( "SB1" , "B1_CONV"	, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )
		cTpConv		:= GetAdvFVal( "SB1" , "B1_TIPCONV"	, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )
		nNewFat		:= GetAdvFVal( "SB1" , "B1_I_FATCO"	, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )

		If cTpConv == "M"
			nQtd2UM	:= IIf( nFatConv == 0 , nNewFat * SZW->ZW_QTDVEN , nFatConv * SZW->ZW_QTDVEN )
		Else
			nQtd2UM	:= IIf( nFatConv == 0 , SZW->ZW_QTDVEN / nNewFat , SZW->ZW_QTDVEN / nFatConv )
		EndIf

		c2UM		:= GetAdvFVal( "SB1" , "B1_SEGUM" , xFilial("SB1") + AllTrim( SZW->ZW_PRODUTO ) , 1 , "" )
		nVlrTot		:= SZW->ZW_QTDVEN * SZW->ZW_PRCVEN
		nVtot		+= nVlrTot

		For nColuna := 1 to Len(aHeader)
			aCols[nLinha][nColuna] := &( aHeader[nColuna][2] )
		Next nColuna

		aCols[nLinha][Len(aHeader)+1] := .F. // Linha não deletada

		SZW->( DBSkip() )
	EndDo

	cFli		:= Space(20)
	cFilPro		:= Space(40)
	cTipPed		:= Space(15)
	cNumPed		:= Space(25)
	cCliente	:= Space(06)
	cNomCli		:= Space(60)
	cLojaCli	:= Space(04)
	cGrpCli		:= Space(30)
	cCond		:= Space(50)
	cVend1		:= Space(06)
	cNmVend1	:= Space(40)
	cVend2		:= Space(06)
	cNmVend2	:= Space(40)
	cPedCli		:= Space(09)
	dDtEnt		:= CtoD("")
	cTipoAg		:= Space(10)
	cHrEnt		:= Space(05)
	cSha		:= Space(14)
	cTipFre		:= Space(10)
	cTipCar		:= Space(15)
	cQtdCha		:= Space(03)
	cHrDes		:= Space(05)
	nCusDes		:= 0
	cClassEnt	:= Space(20)
	cObsCom		:= Space(300)
	cObsNF		:= Space(300)
	cMotRec		:= Space(300)
	nDescFob	:= TRBF->DESCONTO

	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( SubStr( TRBF->FILIAL , 1 , 2 ) + TRBF->NUMPED ) )

	dDtEnt		:= SZW->ZW_FECENT
	_laltera := .T.

	If SZW->ZW_I_AGEND == 'P'

		If month(date()) != 12

			dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+1)))+"0101")-1

		Else

			dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+2)))+"0101")-1

		EndIf

		_laltera := .F.

	EndIf

	If SZW->ZW_I_AGEND $ 'I/O'//I=Imediata //O=Agendada pelo Op.Log.

		_cFilCarreg := SZW->ZW_FILIAL
		If !Empty(SZW->ZW_FILPRO) .And. !(AllTrim(SZW->ZW_FILPRO)=='0')
			_cFilCarreg := SZW->ZW_FILPRO
		EndIf

		//cTipoAg		:= SZW->ZW_I_AGEND+" - IMEDIATO"
		dDtEnt := DATE()+u_omsvldent(DATE(),SZW->ZW_CLIENTE,SZW->ZW_LOJACLI,SZW->ZW_FILIAL,TRBF->NUMPED,1,.F.,_cFilCarreg,SZW->ZW_TIPO,SZW->ZW_TPVENDA)
		_laltera := .F.

	EndIf

	cTipoAg:=SZW->ZW_I_AGEND+" - "+(U_TipoEntrega(SZW->ZW_I_AGEND))
	
	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( cFlVer + TRBF->NUMPED ) )

	lMuda := (SubStr(TRBF->TIPO,1,2) == "05")
	lFrete := TRBF->TPFRETE == "F"
	// aC[n,1] = Nome da Variavel Ex.:"cCliente"
	// aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aC[n,3] = Titulo do Campo
	// aC[n,4] = Picture
	// aC[n,5] = Validacao
	// aC[n,6] = F3
	// aC[n,7] = Se campo e' editavel .T. se nao .F.
	_cclirem := TRBF->CLIREM   //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
	_clojrem := TRBF->LOJEN
	cTipPed	 := SubStr(TRBF->TIPO+" - "+GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+TRBF->TIPO,1,""),1,25)

	_cVal1:=" U_AOM112Val('cFli') "
	_cVal2:=" U_AOM112Val('cFilPro') "
	_cVal3:=" U_AOM112Val('cTipPed',LEFT(cFilPro,2),LEFT(cFli,2)) "
	_cVal4:=" U_AOM112Val('DescBrowser')"
	_cVal5:=" U_AOM112Val('CLIENTE_VENDA')"

	aC := {	{ "cFli"	,{015,003} 	,"Filial                   "   		,"@!"   				,_cVal1,"LSTFAT",.T.},;
		{ "cFilPro"     ,{015,203} 	,"Filial Carregamento"	       	    ,"@!"   				,_cVal2,"ZLSTCA",.T.},;
		{ "cTipPed"		,{030,003} 	,"Tipo Pedido       " 	  			,"@!"   				,_cVal3,"ZB4"	,.T.},;
		{ "cNumPed"		,{030,203} 	,"Num. Pedido           " 			,"@!"   				,	,		,.F.	},;
		{ "cCliente"	,{045,003} 	,"Cliente/Remessa" 	 				,"@!"   				,   ,"SA1"	,.F.	},;
		{ "cLojaCli"	,{045,085} 	,"Loja   "							,"@!"   				,	,		,.F.	},;
		{ "cNomCli"		,{045,140} 	,"Nome Cliente/Remessa"				,"@!"   				,	,		,.F.	},;
		{ "cGrpCli"		,{060,003} 	,"Grupo Cliente/Rem."				,"@!"   				,	,		,.F.	},;
		{ "cCond"		,{060,285} 	,"Cond. Pagto" 						,"@!"   				,	,		,.F.	},;
		{ "cVend1"		,{075,003} 	,"Vendedor 1       "  				,"@!"   				,	,		,.F.	},;
		{ "cNmVend1"	,{075,140} 	,"Nome Vendedor 1" 					,"@!"   				,	,		,.F.	},;
		{ "nVTot"		,{075,500} 	,"Valor Total   " 					,"@e 999,999,999.99"	,	,		,.F.	},;
		{ "cVend2"		,{090,003} 	,"Vendedor 2       "  				,"@!"   				,	,		,.F.	},;
		{ "cNmVend2"	,{090,140} 	,"Nome Vendedor 2" 					,"@!"   				,	,		,.F.	},;
		{ "cPedCli"		,{105,003} 	,"Pedido Cliente/Remessa    "		,"@!"   				,	,		,.F.	},;
		{ "cTipoAg"		,{030,500}	,"Tipo Agendamento"					,"@!"   				,	,		,.F.	},;
		{ "dDtEnt"		,{015,500} 	,"Data Entrega          "			,"@!"   				,	,		,_laltera 	},;
		{ "cHrEnt"		,{105,245} 	,"Hora Entrega   "					,"@E 99:99 "   		    ,	,		,.T. 	},;
		{ "cSha"		,{105,325} 	,"Senha                "			,"@!"   				,	,		,.T.	},;
		{ "cTipFre"		,{105,500} 	,"Tipo Frete    "					,"@!"   				,	,		,.F.	},;
		{ "cTipCar"		,{120,003} 	,"Tipo de Carga     "				,"@!"   				,	,		,.F.	},;
		{ "cQtdCha"		,{120,140} 	,"Qtd. Chapa           "			,"@!"   				,	,		,.F.	},;
		{ "cHrDes"		,{120,245} 	,"Hora Descarga"					,"@!"   				,	,		,.F.	},;
		{ "nCusDes"		,{120,325} 	,"Custo Descarga"					,"@e 999,999,999.99"	,	,		,.F.	},;
		{ "cClassEnt"   ,{120,500}	,"Classif. Entrega"					,"@!"   				,	,		,.F.	},;
		{ "cObsCom"		,{135,003} 	,"Obs. Comercial  "					,"@!"					,	,		,.F.	},;
		{ "cTabelaPrc"	,{150,003} 	,"Cod. Tab. Prc    "				,"@!"					,	,		,.F.	},;
		{ "cDescTabela"	,{150,080} 	,"Desc. Tabela    "					,"@!"					,	,		,.F.	},;
		{ "cVECliente"	,{150,270} 	,"Cliente / Venda"	   			    ,"@!"					,_cVal5,"SA1",.T.	},;
		{ "cVELojaCli"	,{150,355} 	,"    "								,"@!"					,   ,		,.F.	},;
		{ "nDescFob"	,{150,430}	,"Desconto"							,"@e 999,999,999.99"	,_cVal4,	,lFrete } }

	_nLinha:=150
	_nLinha+=15
	aAdd(aC,{ "cMotRec",{_nLinha,003},"Motivo da Recusa"       			 ,"@!",,,.F.})
	_nLinha+=15
	aAdd(aC,{ "_cGData",{_nLinha,003},"Data de Aprovação do Gerente"     ,"@D",,,.F.})
	aAdd(aC,{ "_cCData",{_nLinha,203},"Data de Aprovação do Coordenador" ,"@D",,,.F.})
	_nLinha+=15
	aAdd(aC,{ "_cGHora",{_nLinha,003},"Hora de Aprovação do Gerente"     ,"@!",,,.F.})
	aAdd(aC,{ "_cCHora",{_nLinha,203},"Hora de Aprovação do Coordenador" ,"@!",,,.F.})

	// Array com descricao dos campos do Rodape do Modelo 2
	// aR[n,1] = Nome da Variavel Ex.:"cCliente"
	// aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aR[n,3] = Titulo do Campo
	// aR[n,4] = Picture
	// aR[n,5] = Validacao
	// aR[n,6] = F3
	// aR[n,7] = Se campo e' editavel .T. se nao .F.
	aR := {}

	cClassEnt:=Posicione("SA1",1,xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,"A1_I_CLABC")
	If cClassEnt = '1'
		cClassEnt:="1-TOP 1 NACIONAL"
	ElseIf cClassEnt = '2'
		cClassEnt:="2-TOP 5 Reg. SP"
	ElseIf cClassEnt = '3'
		cClassEnt:="3-TOP 5 Reg. RS"
	EndIf

	cFli		:= LEFT(SubStr(TRBF->FILIAL,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(TRBF->FILIAL,1,2),1,Space(20)),25)
	cFilPro		:= If(!Empty(TRBF->FILPRO),SubStr(TRBF->FILPRO,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(TRBF->FILPRO,1,2),1,Space(35)),Space(35))
	cTipPed	    := SubStr(TRBF->TIPO+" - "+GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+TRBF->TIPO,1,""),1,25)
	cNumPed  	:= TRBF->NUMPED
	cCliente 	:= SZW->ZW_CLIENTE
	cLojaCli 	:= SZW->ZW_LOJACLI
	cNomCli 	:= GetAdvFVal("SA1","A1_NOME",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")
	cGrpCli		:= GetAdvFVal("SA1","A1_GRPVEN",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")+" - "+GetAdvFVal("SA1","A1_I_NGRPC",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")
	ccond       := AOMS1125()
	cVend1	 	:= SZW->ZW_VEND1
	cNmVend1 	:= GetAdvFVal("SA3","A3_NOME",xFilial("SA3")+SZW->ZW_VEND1,1,"")
	cVend2   	:= SZW->ZW_VEND2
	cNmVend2 	:= GetAdvFVal("SA3","A3_NOME",xFilial("SA3")+SZW->ZW_VEND2,1,"")
	nVTot 		:= nVTot
	cPedCli		:= SZW->ZW_PEDCLI
	dDtEnt		:= SZW->ZW_FECENT
	cHrEnt		:= SZW->ZW_HOREN
	cSha		:= SZW->ZW_SENHA
	cTipFre		:= If(SZW->ZW_TPFRETE == 'C',SZW->ZW_TPFRETE+" - CIF",SZW->ZW_TPFRETE+" - FOB")
	_cchep 		:= Posicione("SA1",1,xFilial("SA1")+ccliente+cLojaCli,"A1_I_CCHEP")
	cTipCar		:= If( !Empty(_cchep) , "1 - Paletizada" , "2 - Batida" )
	cQtdCha		:= SZW->ZW_CHAPA
	cHrDes		:= SZW->ZW_HORDES
	nCusDes		:= SZW->ZW_CUSDES
	cObsCom		:= SZW->ZW_OBSCOM
	cObsNF		:= SZW->ZW_MENNOTA
	cMotRec	    := AllTrim(SZW->ZW_MOTREC)
	cMotRec	    := cMotRec+Space(300-Len(cMotRec))

	aCGD		:= { 350 , 06 , 26 , 74 } // Array com coordenadas da GetDados no modelo2

	cTabelaPrc	:= SZW->ZW_TABELA //aTabPrc[1]
	cDescTabela	:= AllTrim(Posicione("DA0",1,xFilial("DA0")+SZW->ZW_TABELA,"DA0_DESCRI"))
	cVECliente	:= SZW->ZW_CLIREM //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
	cVELojaCli	:= TRBF->LOJEN
	_cGData     := SZW->ZW_I_DLIBG
	_cGHora     := SZW->ZW_I_HLIBG
	_cCData     := SZW->ZW_DATAAPR 
	_cCHora     := SZW->ZW_HORAAPR 

	// Chamada da Modelo2
	//( cTitulo , aC , aR , aGd  , nOp   ,cLinhaOk,cTudoOk ,aGetsD,bF4,cIniCpos,nMax,aCordW,lDelGetD,lMaximazed ] [ aButtons ] )
	lRetMod2 := Modelo2( cTitulo , aC , aR , aCGD , 6 ,        ,  , aR   ,   ,        ,9999,      ,        , .T. ,_aButtons)

	If lRetMod2

		_cUpudate:= "UPDATE SZW010 SET ZW_FILIAL = '"+ SubStr(cFli   ,1,2) +;
			"',ZW_FILPRO  = '"+ SubStr(cFilPro,1,2) +;
			"',ZW_TIPO    = '"+ SubStr(cTipPed,1,2) +;
			"',ZW_FECENT  = '"+ DToS(dDtEnt) +;
			"',ZW_HOREN   = '"+ cHrEnt +;
			"',ZW_CLIREM  = '"+ cVECliente +; //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
			"',ZW_LOJEN   = '"+ cVELojaCli +;
			"',ZW_CLIENTE = '"+ cCliente+;
			"',ZW_LOJACLI = '"+ cLojaCli+;
			"',ZW_FOBDESC = '"+ Str(nDescFob,14,2)+;
		"',ZW_SENHA = '"+ cSha+;
			"' WHERE ZW_IDPED = '"+ cNumPed +;
			"' AND D_E_L_E_T_ = ' ' "
		_nRet:=TcSqlExec( _cUpudate )
		_nRet:=TcSqlExec( "COMMIT"  )

		TRBF->FILIAL   := AllTrim(SubStr(cFli,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(cFli,1,2),1,""))
		TRBF->FILPRO   := If(!Empty(cFilPro),AllTrim(SubStr(cFilPro,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(cFilPro,1,2),1,"")),"")
		TRBF->RFILIAL  := AllTrim(SubStr(cFli,1,2))
		TRBF->TIPO     := cTipPed+" - "+GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+cTipPed,1,"")
		TRBF->DT_ENTREG:= DToC(dDtEnt)
		TRBF->HORAENTR := cHrEnt
		TRBF->CLIREM	:= cVECliente //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
		TRBF->LOJEN		:= cVELojaCli
		TRBF->CODCLI    := cCliente
		TRBF->LOJA      := cLojaCli
		TRBF->DESCONTO	:= nDescFob

		// GRAVAÇÃO DOS DADOS DO ARMAZEM
		SZW->( DBSetOrder(1) ) // ZW_FILIAL+ZW_IDPED
		If SZW->( DBSeek( cFlVer + TRBF->NUMPED ) )
			While !SZW->(Eof()) .And. SZW->(ZW_FILIAL+ZW_IDPED) == cFlVer + TRBF->NUMPED
				_nI := aScan(aCols,{|x| x[_nPosItem] == SZW->ZW_ITEM})  // _nPosLocal // ZW_ITEM

				If _nI > 0
					SZW->(RecLock("SZW",.F.))
					SZW->ZW_LOCAL 	:= aCols[_nI,_nPosLocal]
					SZW->(MSUnLock())
				EndIf

				SZW->(DBSkip())
			EndDo
		EndIf
		_cCliRem	:= cVECliente
		_cLojRen	:= cVELojaCli

		omark:aArray[omark:NAT,A112MAP("Tipo")] := cTipPed
		omark:aArray[omark:NAT,A112MAP("Filial Faturamento")] := cFli
		omark:aArray[omark:NAT,A112MAP("Filial Carregamento")] := cFilPro
		omark:aArray[omark:NAT,A112MAP("Cliente/Remessa")] := TRBF->CODCLI + "/" + TRBF->LOJA + " - " + Posicione("SA1",1,xFilial("SA1")+AllTrim(TRBF->CODCLI)+AllTrim(TRBF->LOJA),"A1_NOME")

		If Empty(_cclirem)
			omark:aArray[omark:NAT,A112MAP("Cliente/Venda")] :=  "  "
		Else
			omark:aArray[omark:NAT,A112MAP("Cliente/Venda")] := TRBF->CLIREM + "/" + TRBF->LOJEN + " - " + Posicione("SA1",1,xFilial("SA1")+AllTrim(TRBF->CLIREM)+AllTrim(TRBF->LOJEN),"A1_NOME") //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
		EndIf

		omark:aArray[omark:NAT,A112MAP("Desconto")] := nDescFob
		omark:aArray[omark:NAT,A112MAP("Dt Entrega")] := dDtEnt

		omark:refresh()
	EndIf
Else
	U_ITMsg( 'Falha ao posicionar no pedido!' , 'Atenção!',,1 )
EndIf

AOMS112UN( cFlVer, TRBF->NUMPED)

_nposi := TRBF->(Recno())
TRBF->(DBGoTo(_nposi))
TRBF->(DBSkip())

Return

/*
===============================================================================================================================
Programa--------: AOMS112LO
Autor-----------: Josué Danich
Data da Criacao-: 25/11/2015
Descrição-------: Locka registros do pedido
Parametros------: _cfilAux - Filial do pedido
					_cnumped - Numero do pedido
Retorno---------: _lRet - se conseguiu ou não lockar os registros do pedido
===============================================================================================================================
*/
Static Function AOMS112LO(_cFilAux,_cNumPed,_lMen)

Local _lRet := .T.
Local _aarea := FWGetArea()

Default _lTela := !FWGetRunSchedule()
Default _lMen := .T.
//Bloqueia o pedido na pesquisa, para que não seja possivel enquanto esta rotina estiver sendo utilizada a sua alteracao	
DBSelectArea("SZW")
SZW->( DBSetOrder(1) )

If SZW->( DBSeek( _cFilAux + _cNumPed ) )
	While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == _cFilAux + _cNumPed .And. _lRet
		If SZW->( DBRLock() )
			SZW->( MSUnLock())
			RecLock("SZW",.F.)
			SZW->( DBSkip() )
		Else
			If _lTela
				If(_lMen,U_ITMsg( "Falha ao reservar o pedido, está em uso por outra estação" , "Atenção!" , ,1 ),)
			EndIf
			_lRet  := .F.
		EndIf
	EndDo
Else
	If _lTela
	   If(_lMen,U_ITMsg( "Pedido não localizado na base de Dados: " + _cNumPed   , "Atenção!","Informar a área de TI/ERP" ,1 ),)
    EndIf
	_lRet := .F.
EndIf

FWRestArea( _aarea)

Return _lRet

/*
===============================================================================================================================
Programa----------: AOM112Val()
Autor-------------: Alex Wallauer
Data da Criacao---: 12/08/2016
Descrição---------: Funcao utilizada para verificar os campos da tela
Parametros--------: cCampo := Origem da chamada
Retorno-----------: Lógico
===============================================================================================================================
*/
User Function AOM112Val( cCampo , _cFil_Carr , _cFil_Fat )

Local _lRet	:= .T.,cFilsFat
Local _nne	:= 0
Do Case

Case cCampo == 'WHEN_IMPRIME'
	_lRet:=( LEFT(aarr[oMark:naT,A112MAP(Space(3))],4) == "1" )

Case cCampo == 'VAL_IMPRIME'

	If LEFT(M->IMPRIME,1) <> "2"
		U_ITMsg("Só permitido prencher com 2 = Não",'Atenção',,1)
		_lRet:= .F.
	Else

		M->IMPRIME:="2-NÃO"

		TRBF->(DBGoTo(aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]))
		TRBF->( RecLock( "TRBF" , .F. ) )
		TRBF->IMPRIME:=M->IMPRIME
		TRBF->( MSUnLock() )

		aarr[oMark:naT,A112MAP(Space(3))]:=M->IMPRIME//Tem que atualizar o aarr Tb

		_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_IMPRIME = '2' " +;
			" WHERE ZW_IDPED = '"+ aarr[oMark:naT,A112MAP("Id Pedido")] +;
			"' AND D_E_L_E_T_ = ' ' ")
		_nRet:=TcSqlExec( "COMMIT" )

	EndIf

Case cCampo == 'CLIENTE_VENDA'

	If AllTrim(SZW->ZW_CLIREM) == AllTrim(cVECliente)
		Return .T.
	EndIf

	If Empty(cVECliente) .And. LEFT(cTipPed,2) $ _cOperTriangular
		U_ITMsg("Cliente / Venda nao preenchida",'Atenção',,1)
		_lRet:= .F.
	ElseIf !Empty(cVECliente) .And. !LEFT(cTipPed,2) $ _cOperTriangular
		U_ITMsg("Cliente / Venda nao pode ser preenchido",'Atenção',,1)
	cVELojaCli:=Space( Len(SZW->ZW_LOJEN) )
		_lRet:= .F.
	EndIf

	SA1->(DBSetOrder(1))
	If _lRet .And. !(SA1->(DBSeek(xFilial("SA1")+cVECliente+cVELojaCli)))
		U_ITMsg("Cliente / Venda  não localizado no cadastro","Atenção",,1)
		_lRet := .F.
	ElseIf _lRet .And. SA1->A1_MSBLQL = '1'
		U_ITMsg("Cliente / Venda  bloqueado","Atenção",,1)
		_lRet := .F.
		//Não pode escolher mesmo cliente do pedido para remessa
	ElseIf !Empty(cVECliente) .And. AllTrim(cVECliente)+AllTrim(cVELojaCli) == AllTrim(cCliente)+AllTrim(cLojaCli)
		U_ITMsg("Não é permitido escolher mesmo Cliente/Remessa do pedido para remessa","Atenção",,1)
		_lRet := .F.
	EndIf

Case cCampo == 'cFli'//Filial de Faturamento

	If AllTrim(SubStr(cfli,1,2)) == AllTrim(SZW->ZW_FILIAL)
		cfli:= SubStr(cfli,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(cfli,1,2),1,"")
		Return .T.
	EndIf

	If Empty(cFli)
		U_ITMsg("Filial nao preenchida",'Atenção',,1)
		_lRet:= .F.
	Else
		cFliDesc:=GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(cFli,1,2),1,"")

		If Empty(cFliDesc)
			U_ITMsg("Filial nao cadastrada",'Atenção',,1)
			Return .F.
		EndIf

		cFli:=SubStr(cFli,1,2)+" - "+cFliDesc

		_cFilSalva:= cFilAnt
		cFilAnt   := cFli
		If AllTrim(SuperGetMV("IT_FATNF",.T.,"N")) == "N"
			cFilPro:= Space(02)
		EndIf
		cFilAnt := _cFilSalva

		If !Empty(cFilPro)               //Fil Carregamento Fil Faturamento
			Return U_AOM112Val( 'VAL_GRUPO' , LEFT(cFilPro,2) , LEFT(cFli,2) )
		EndIf

	EndIf

	If _lRet

		//Atualiza armazéns
		SBZ->(DBSetOrder(1)) //BZ_FILIAL+BZ_COD

		For _nne := 1 to Len(acols)
			_carmi := Posicione("SB1",1,xFilial("SB1")+acols[_nne][2],"B1_LOCPAD")
			If Empty(SubStr(cFilPro,1,2))
				_cfili := LEFT(cFli,2)
			Else
				_cfili := SubStr(cFilPro,1,2)
			EndIf

			If SBZ->(DBSeek(_cfili+acols[_nne][2]))
				_carmi := SBZ->BZ_LOCPAD
			EndIf

			If AllTrim(_carmi) != AllTrim(acols[_nne][11])
				acols[_nne][11] := AllTrim(_carmi)
				xObj := CallMod2Obj()
				xObj:oBrowse:Refresh()
			EndIf
		Next
	EndIf

Case cCampo == 'cFilPro'

	If AllTrim(SubStr(cFilPro,1,2)) == AllTrim(SZW->ZW_FILPRO)
		cFilPro:= SubStr(cFilPro,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(cFilPro,1,2),1,"")
		Return .T.
	EndIf

	If !Empty(cFilPro)//Filial de Carregamento

		cFilDes:= GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(cFilPro,1,2),1,"")
		If Empty(cFilDes)
			U_ITMsg("Filial nao cadastrada",'Atenção',,1)
			Return .F.
		EndIf
		cFilPro:= SubStr(cFilPro,1,2)+" - "+cFilDes

		_cFilSalva:= cFilAnt
		cFilAnt   := LEFT(cFli,2)
		If AllTrim(SuperGetMV("IT_FATNF",.T.,"N")) == "N"
			U_ITMsg("Filial do Pedido nao é troca nota: "+cFli,'Atenção',,1)
			_lRet	:= .F.
		EndIf

		cFilAnt:=LEFT(cFilPro,2)
		If AllTrim(SuperGetMV("IT_PRONF",.T.,"N")) == "N"
			U_ITMsg("Filial de Carregamento do Pedido seleciona nao é troca nota: "+cFilPro,'Atenção',,1)
			_lRet	:= .F.
		EndIf
		cFilAnt := _cFilSalva

		If _lRet                         //Fil Carregamento Fil Faturamento
			_lRet:=U_AOM112Val( 'VAL_GRUPO' , LEFT(cFilPro,2) , LEFT(cFli,2) )
		EndIf


	EndIf

	If _lRet

		//Atualiza armazéns
		SBZ->(DBSetOrder(1)) //BZ_FILIAL+BZ_COD

		For _nne := 1 to Len(acols)

			_carmi := Posicione("SB1",1,xFilial("SB1")+acols[_nne][2],"B1_LOCPAD")

			If Empty(SubStr(cFilPro,1,2))

				_cfili := LEFT(cFli,2)

			Else

				_cfili := SubStr(cFilPro,1,2)

			EndIf

			If SBZ->(DBSeek(_cfili+acols[_nne][2]))

				_carmi := SBZ->BZ_LOCPAD

			EndIf

			If AllTrim(_carmi) != AllTrim(acols[_nne][11])

				acols[_nne][11] := AllTrim(_carmi)
				xObj := CallMod2Obj()
				xObj:oBrowse:Refresh()

			EndIf

		Next

	EndIf


Case cCampo == 'cTipPed'

	If Empty(cTipPed)
		U_ITMsg("Tipo nao preenchida",'Atenção',,1)
		_lRet:= .F.
	Else

		cTipPeDesc:=GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+LEFT(cTipPed,2),1,"")
		If Empty(cTipPeDesc)
			U_ITMsg("Tipo nao cadastrado",'Atenção',,1)
			Return .F.
		EndIf
		cTipPed:=LEFT(cTipPed,2)+" - "+cTipPeDesc

		If cTipPed = _cOperRemessa// Tratamento da Operação Triangular
			U_ITMsg("Código do Tipo não pode ser "+_cOperRemessa,"Atenção!","Selecione um tipo diferente de "+_cOperRemessa,1)
			Return .F.
		ElseIf AllTrim(cTipPed)  = _cOperFat .And. !Empty(_cFil_Carr) .And. _cFil_Carr <> _cFil_Fat//TROCA NOTA
			U_ITMsg("Pedidos de operação triangular "+_cOperTriangular+", não podem ser troca nota","Atenção!","Altere para o pedido não ser troca nota ou o tipo da operação não ser "+_cOperFat,1)
			Return .F.
		EndIf

		If !LEFT(cTipPed,2) $ _cOperTriangular
			cVECliente:=Space( Len(SZW->ZW_CLIREM))
			cVELojaCli:=Space( Len(SZW->ZW_LOJEN) )
		ElseIf Empty(cVECliente)
			cVECliente:= SZW->ZW_CLIREM
			cVELojaCli:= SZW->ZW_LOJEN
		EndIf

	EndIf

Case cCampo == 'FilProBrowse'//Filial de Carregamento

	If !Empty(aarr[oMark:nat,A112MAP("Filial Carregamento")])

		cFilDes:= GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+LEFT(aarr[oMark:nat,A112MAP("Filial Carregamento")],2),1,"")
		If Empty(cFilDes)
			U_ITMsg("Filial nao cadastrada",'Atenção',,1)
			Return .F.
		EndIf

		_cFilSalva:= cFilAnt
		cFilAnt   := LEFT(AllTrim(aarr[oMark:naT,A112MAP("Filial Faturamento")]),2)//Pega a Filial de Faturamento na sexta coluna
		If AllTrim(SuperGetMV("IT_FATNF",.T.,"N")) == "N"
			U_ITMsg("Filial "+AllTrim(aarr[oMark:naT,A112MAP("Impresso")])+" nao é troca nota de Faturamento (IT_FATNF)",'Atenção',,1)
			_lRet:= .F.
		EndIf

		cFilAnt:=LEFT(aarr[oMark:nat,A112MAP("Filial Carregamento")],2)
		If AllTrim(SuperGetMV("IT_PRONF",.T.,"N")) == "N"
			U_ITMsg("Filial "+AllTrim(M->FILPRO)+" nao é troca nota de Carregamento (IT_PRONF)",'Atenção',,1)
			_lRet:= .F.
		EndIf
		cFilAnt  := _cFilSalva

		If _lRet                             //Fil Carregamento, Fil Faturamento
			_lRet:=U_AOM112Val( 'VAL_GRUPO' , LEFT(aarr[oMark:nat,A112MAP("Filial Carregamento")],2) , LEFT(aarr[oMark:naT,A112MAP("Filial Faturamento")],2) )
		EndIf

		aarr[oMark:nat,A112MAP("Filial Carregamento")]:= LEFT(LEFT(aarr[oMark:nat,A112MAP("Filial Carregamento")],2)+" - "+cFilDes,40)

	EndIf

	If _lRet

		TRBF->(DBGoTo(aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]))
		TRBF->FILPRO:=aarr[oMark:nat,A112MAP("Filial Carregamento")]

		_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_FILPRO = '"+ SubStr(aarr[oMark:nat,A112MAP("Filial Carregamento")],1,2) +;
			"' WHERE ZW_IDPED = '"+ AllTrim(aarr[oMark:naT,A112MAP("Id Pedido")]) +;
			"' AND D_E_L_E_T_ = ' ' ")
		_nRet:=TcSqlExec( "COMMIT" )

		//Atualiza armazéns conforme filial de faturamento e carregamento
		SBZ->(DBSetOrder(1)) //BZ_FILIAL+BZ_COD
		SZW->(DBSetOrder(1)) //ZW_FILIAL+ZW_IDPED
		SZW->(DBSeek(SubStr(aarr[oMark:naT,A112MAP("Filial Faturamento")],1,2)+AllTrim(aarr[oMark:naT,A112MAP("Id Pedido")])))

		While SZW->ZW_FILIAL == SubStr(aarr[oMark:naT,A112MAP("Filial Faturamento")],1,2) .And. AllTrim(SZW->ZW_IDPED) = AllTrim(aarr[oMark:naT,A112MAP("Id Pedido")])

			_carmi := Posicione("SB1",1,xFilial("SB1")+SZW->ZW_PRODUTO,"B1_LOCPAD")

			If Empty(SubStr(aarr[oMark:nat,A112MAP("Filial Carregamento")],1,2))

				_cfili := SubStr(aarr[oMark:naT,A112MAP("Filial Faturamento")],1,2)

			Else

				_cfili := SubStr(aarr[oMark:nat,A112MAP("Filial Carregamento")],1,2)

			EndIf

			If SBZ->(DBSeek(_cfili+SZW->ZW_PRODUTO))

				_carmi := SBZ->BZ_LOCPAD

			EndIf

			If AllTrim(_carmi) != AllTrim(SZW->ZW_LOCAL)

				RecLock("SZW", .F.)
				SZW->ZW_LOCAL := _carmi
				SZW->(MSUnLock())

			EndIf

			SZW->(DBSkip())

		EndDo

	EndIf

Case cCampo == 'FilFatBrowse'//Filial de Faturamento

	If !Empty(aarr[oMark:nat,A112MAP("Filial Faturamento")]) //"FILIAL"

		cFilDes:= GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+LEFT(aarr[oMark:nat,A112MAP("Filial Faturamento")],2),1,"")
		If Empty(cFilDes)
			U_ITMsg("Filial nao cadastrada",'Atenção',,1)
			Return .F.
		EndIf

		If !Empty(LEFT(aarr[oMark:naT,A112MAP("Filial Carregamento")],2))//Se preenchida a Filial de Carregamento na quarta coluna faz as valdações
			_cFilSalva:= cFilAnt

			cFilAnt:=LEFT(aarr[oMark:nat,A112MAP("Filial Faturamento")],2)
			If AllTrim(SuperGetMV("IT_FATNF",.T.,"N")) == "N" //Se tá preenchida a coluna de Carregamento essa filial tem que ser TN de Faturamento
			U_ITMsg("Filial "+AllTrim(aarr[oMark:nat,A112MAP("Filial Faturamento")])+" nao é Troca Nota de Faturamento (IT_FATNF)",'Atenção',,1)
				_lRet:= .F.
			EndIf

			//Se tá preenchida a coluna de Carregamento essa filial tem que ser do grupo dela
			If _lRet                                  //Fil Carregamento        Fil Faturamento
				_lRet:=U_AOM112Val( 'VAL_GRUPO' , LEFT(aarr[oMark:naT,A112MAP("Filial Carregamento")],2)  , LEFT(aarr[oMark:nat,A112MAP("Filial Faturamento")],2) )
			EndIf


		EndIf

		aarr[oMark:nat,A112MAP("Filial Faturamento")]:= LEFT(LEFT(aarr[oMark:nat,A112MAP("Filial Faturamento")],2)+" - "+cFilDes,40)

	Else
		U_ITMsg("Filial de Faturamento nao Preenchida",'Atenção',,1)
		Return .F.

	EndIf

	TRBF->(DBGoTo(aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]))
	TRBF->( RecLock( "TRBF" , .F. ) )
	TRBF->FILIAL:=aarr[oMark:nat,A112MAP("Filial Faturamento")]    //M->FILIAL
	TRBF->( MSUnLock() )

	_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_FILIAL = '"+ SubStr(aarr[oMark:nat,A112MAP("Filial Faturamento")],1,2) +;
		"' WHERE ZW_IDPED = '"+ AllTrim(aarr[oMark:naT,A112MAP("Id Pedido")]) +;
		"' AND D_E_L_E_T_ = ' ' " )
	_nRet:=TcSqlExec( "COMMIT" )

	//Atualiza armazéns conforme filial de faturamento e carregamento
	SBZ->(DBSetOrder(1)) //BZ_FILIAL+BZ_COD
	SZW->(DBSetOrder(1)) //ZW_FILIAL+ZW_IDPED
	SZW->(DBSeek(SubStr(aarr[oMark:nat,A112MAP("Filial Faturamento")],1,2)+aarr[oMark:naT,A112MAP("Filial Faturamento")]))

	While SZW->ZW_FILIAL == SubStr(aarr[oMark:nat,A112MAP("Filial Faturamento")],1,2) .And. AllTrim(SZW->ZW_IDPED) = AllTrim(aarr[oMark:naT,A112MAP("Filial Faturamento")])

		_carmi := Posicione("SB1",1,xFilial("SB1")+SZW->ZW_PRODUTO,"B1_LOCPAD")

		If SBZ->(DBSeek(SubStr(aarr[oMark:nat,A112MAP("Filial Faturamento")],1,2)+SZW->ZW_PRODUTO))

			_carmi := SBZ->BZ_LOCPAD

		EndIf

		If AllTrim(_carmi) != AllTrim(SZW->ZW_LOCAL)

			RecLock("SZW", .F.)
			SZW->ZW_LOCAL := _carmi
			SZW->(MSUnLock())

		EndIf

		SZW->(DBSkip())

	EndDo


Case cCampo == "DescBrowser" //DESCONTO
	TRBF->(DBGoTo(aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]))
	If Type("nDescFob") == "N"
		If nDescFob > TRBF->VALOR
			U_ITMsg("O valor do desconto não pode ser maior que o valor do pedido.",'Atenção',,1)
			nDescFob := TRBF->DESCONTO
			Return .F.
		Else
			Return .T.
		EndIf
	EndIf

	If AARR[oMark:Nat][A112MAP("Desconto")] < AARR[oMark:Nat][A112MAP("Valor Pedido")]

		TRBF->( RecLock( "TRBF" , .F. ) )
		TRBF->DESCONTO := AARR[oMark:Nat][A112MAP("Desconto")]
		TRBF->( MSUnLock() )

		_nRet:=TcSqlExec( "UPDATE SZW010 SET ZW_FOBDESC = "+Str(AARR[oMark:Nat][A112MAP("Desconto")],14,2)+" " +;
			" WHERE ZW_IDPED = '"+ aarr[oMark:naT,A112MAP("Id Pedido")] +;
			"' AND D_E_L_E_T_ = ' ' ")
		_nRet:=TcSqlExec( "COMMIT" )
		Return .T.
	Else
		U_ITMsg("O valor do desconto não pode ser maior que o valor do pedido.",'Atenção',,1)
		Return .F.
	EndIf


Case cCampo == 'VAL_GRUPO'

	If _cFil_Carr == _cFil_Fat
		Return .T.
	EndIf

	cFilsFat:= AllTrim(GetAdvFVal("ZZM","ZZM_FILFAT",xFilial("ZZM")+_cFil_Carr,1,""))
	If Empty(cFilsFat)//Testa se a filial de faturamento esta no grupo do campo ZZM

		U_ITMsg("Filial de Carregamento: "+_cFil_Carr+" não possui grupo de Filiais de Faturamento",;
			"Validação de filial","Entre em contato com a area de TI para cadastrar novas filiais no grupo no Configurador Italac \ Usuários \ Cad Filiais.",1)

		Return .F.
	ElseIf !(_cFil_Fat $ cFilsFat)//Testa se a filial de faturamento esta no grupo do campo ZZM

		U_ITMsg("Filial de Faturamento "+_cFil_Fat+" nao esta no grupo de filiais ("+cFilsFat+") da Filial de Carregamento: "+_cFil_Carr,;
			"Validação de filial","Entre em contato com a area de TI para cadastrar novas filiais no grupo no Configurador Italac \ Usuários \ Cad Filiais.",1)

		Return .F.
	EndIf

Case cCampo == 'TipoBrowse'

	cTipPed:=LEFT(aarr[oMark:nat,A112MAP("Tipo")],2)
	TRBF->(DBGoTo(aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]))

	If AllTrim(TRBF->TIPO) == AllTrim(SubStr(cTipPed,1,2))
		aarr[oMark:nat,A112MAP("Tipo")]:= LEFT(cTipPed,2)+" - "+GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+LEFT(cTipPed,2),1,"")
		Return .T.
	EndIf

	If Empty(cTipPed)
		U_ITMsg("Tipo nao preenchida",'Atenção',,1)
		Return .F.

	Else//If !Empty(cTipPed)

		cTipPeDesc:=GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+cTipPed,1,"")
		If Empty(cTipPeDesc)
			U_ITMsg("Tipo Operação nao cadastrada",'Atenção',,1)
			Return .F.
		EndIf
		cTipPed := cTipPed+" - "+cTipPeDesc

		If cTipPed = _cOperRemessa// Tratamento da Operação Triangular (42)
			U_ITMsg("Código do Tipo não pode ser "+_cOperRemessa,"Atenção!","Selecione um tipo diferente de "+_cOperRemessa,1)
			Return .F.
		ElseIf AllTrim(cTipPed)  = _cOperFat .And. !Empty(LEFT(TRBF->FILPRO,2)) .And. LEFT(TRBF->FILPRO,2) <> LEFT(TRBF->FILIAL,2)//TROCA NOTA
			U_ITMsg("Pedidos de operação triangular "+_cOperTriangular+", não podem ser troca nota","Atenção!","Altere para o pedido não ser troca nota ou o tipo da operação não ser "+_cOperFat,1)
			Return .F.
		EndIf

		aarr[oMark:nat,A112MAP("Tipo")]:= cTipPed
		If !LEFT(cTipPed,2) $ _cOperTriangular
			aArr[oMark:nat,A112MAP("Cliente/Venda")]:= Space( 100 )
		EndIf

	EndIf

	If _lRet

		TRBF->(DBGoTo(aarr[OMARK:NAT,Len(aarr[OMARK:NAT])]))
		TRBF->TIPO:=cTipPed
		If !LEFT(cTipPed,2) $ _cOperTriangular
			TRBF->CLIREM:= Space( Len(SZW->ZW_CLIREM))
			TRBF->LOJEN := Space( Len(SZW->ZW_LOJEN))
		EndIf

		_cQueryAtu:="UPDATE SZW010 SET ZW_TIPO = '"+ LEFT(cTipPed,2) +"' "
		If !LEFT(cTipPed,2) $ _cOperTriangular
			_cQueryAtu+=" ,ZW_CLIREM  = '"+Space( Len(SZW->ZW_CLIREM))+"' "
			_cQueryAtu+=" ,ZW_LOJEN   = '"+Space( Len(SZW->ZW_LOJEN)) +"' "
		EndIf
		_cQueryAtu+=" WHERE ZW_IDPED = '"+ AllTrim(aarr[oMark:naT,A112MAP("Id Pedido")]) +"' "
		_cQueryAtu+=" AND D_E_L_E_T_ = ' ' "
		_nRet:=TcSqlExec( _cQueryAtu )
		_nRet:=TcSqlExec( "COMMIT" )

	EndIf

EndCase

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS112UN
Autor-----------: Josué Danich
Data da Criacao-: 25/11/2015
Descrição-------: UnLocka registros do pedido
Parametros------: _cfilAux - Filial do pedido
					_cnumped - Numero do pedido
Retorno---------: _lRet - se conseguiu ou não lockar os registros do pedido
===============================================================================================================================
*/
Static Function AOMS112UN(_cFilAux,_cNumPed)

Local _aarea := getarea("SZW")


DBSelectArea("SZW")
SZW->( DBSetOrder(1) )

If SZW->( DBSeek( _cFilAux + _cNumPed ) )

	While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == _cFilAux + _cNumPed


		SZW->( MSUnLock())
		SZW->( DBSkip() )

	EndDo

EndIf

FWRestArea( _aarea)

Return

/*
===============================================================================================================================
Programa--------: AOMS112IM
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Função que chama a impressão e controla a atualização do status de impresso
Parametros------: oproc - objeto da barra de processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112IM(oproc)

Local _nposi := TRBF->(Recno())
Private _aPed			:= {}
Private _nRadMnu1    := 1

TRBF->( DBGoTop() )

//Imprime todos os pedidos selecionados
While TRBF->(!Eof())

	// Somente pedidos selecionados pelo usuario
	If (TRBF->OK == cmarca .And. !linverte) .Or. (TRBF->OK != cmarca .And. linverte)

		SZW->(DBSetOrder(1))
		If SZW->(DBSeek(SubStr(TRBF->FILIAL,1,2)+TRBF->NUMPED))
			aAdd(_aped,{AllTrim(SZW->ZW_FILIAL) ,AllTrim(SZW->ZW_IDPED) , AllTrim(SZW->ZW_CLIENTE) , AllTrim(SZW->ZW_LOJACLI) ,  SZW->ZW_VEND1 })

			TRBF->( RecLock( "TRBF", .F. ) )
			TRBF->IMPRIME := '1-SIM'
			TRBF->( MSUnLock() )

			//aarr[aScan(aarr,{|x| x[21] == TRBF->(Recno())}),04] := '1-SIM'
			aarr[aScan(aarr,{|x| x[Len(x)] == TRBF->(Recno())}),04] := '1-SIM'

			SZW->( RecLock( "SZW", .F. ) )
			SZW->ZW_IMPRIME := '1'
			SZW->( MSUnLock() )

		EndIf

	EndIf

	TRBF->(DBSkip())

EndDo

If Len(_aped) = 0

	//Imprime somente pedido posicionado
	TRBF->(DBGoTo(_nposi))
	SZW->(DBSetOrder(1))
	If SZW->(DBSeek(SubStr(TRBF->FILIAL,1,2)+TRBF->NUMPED))

		_aPed			:= {{AllTrim(SZW->ZW_FILIAL) ,AllTrim(SZW->ZW_IDPED) , AllTrim(SZW->ZW_CLIENTE) , AllTrim(SZW->ZW_LOJACLI) ,  SZW->ZW_VEND1 }}

		U_ROMS035R(oproc)

		TRBF->(DBGoTo(_nposi))
		TRBF->( RecLock( "TRBF", .F. ) )
		TRBF->IMPRIME := '1-SIM'
		TRBF->( MSUnLock() )

		aarr[aScan(aarr,{|x| x[Len(x)] == TRBF->(Recno())}),04] := '1-SIM'

		SZW->( RecLock( "SZW", .F. ) )
		SZW->ZW_IMPRIME := '1'
		SZW->( MSUnLock() )

	EndIf

Else

	U_ROMS035R(oproc)

EndIf

omark:refresh()
ProcessMessages()

//Retorna browse ao pedidos posicionado
TRBF->(DBGoTo(_nposi))

Return

/*
===============================================================================================================================
Programa--------: AOMS112LEG
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Exibe a tela de detalhes da legenda
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112LEG()

Local cCadastro := OemToAnsi( "Pedidos do Portal" )

BrwLegenda( cCadastro   , "Legenda" ,;
	{{"BR_VERMELHO"     , "Pedido aguardando  Efetivação" 		} ,;
	{ "BR_PRETO"        , "Pedido com Preço   Bloqueado" 		} ,;
	{ "BR_VIOLETA"      , "Pedido com Preço   Rejeitado" 		} ,;
	{ "ENABLE"          , "Pedido com Preço   Liberado"  		} ,;
	{ "BR_AZUL"         , "Pedido com Crédito Bloqueado" 		} ,;
	{ "BR_LARANJA"      , "Pedido com Crédito Rejeitado" 		} ,;
	{ "BR_MARRON_OCEAN" , "Pedido Bonificação Bloqueado" 		} ,;
	{ "BR_MARRON"       , "Pedido Bonificação Rejeitado" 		} ,;
	{ "BR_AMARELO"      , "Pendente Aprov. Preço P/Coordenador"	} ,;
	{ "BR_VERDE_ESCURO" , "Pendente Aprov. Preço P/Gerente"		} ,;
	{ "BR_CANCEL"       , "Pedido com Cliente/Remessa Bloqueado"} })

Return(.T.)

/*
===============================================================================================================================
Programa----------: AOMS112EC()
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/03/2019
Descrição---------: Exporta browse para o excel
Parametros--------: oproc - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112EC(oproc)

Local _acolec := {}
Local _aheaderec := {}
Local _nnh		:= 0
//Monta aheader
aAdd(_aheaderec,"Impresso")             //01
aAdd(_aheaderec,"Dias/Horas Pendentes") //02
aAdd(_aheaderec,"Filial Faturamento" )  //03
aAdd(_aheaderec,"Filial Carregamento")  //04
aAdd(_aheaderec,"Id Pedido")            //05
aAdd(_aheaderec,"Tipo")                 //06
aAdd(_aheaderec,"Cliente/Venda"  )      //07
aAdd(_aheaderec,"Cliente/Remessa")      //08
aAdd(_aheaderec,"Valor do Pedido")      //09
aAdd(_aheaderec,"Tipo Entrega")         //10
aAdd(_aheaderec,"Dt Entrega")           //11
aAdd(_aheaderec,"Tipo Frete")           //12
aAdd(_aheaderec,"Peso Bruto")           //13
aAdd(_aheaderec,"Desconto")             //14
aAdd(_aheaderec,"Obs")                  //15
aAdd(_aheaderec,"Mens NF")              //16
aAdd(_aheaderec,"Classificacao Entrega")//17

//Monta acols
For _nnh := 1 to Len(aarr)

	If aarr[_nnh][1] == cmarca .Or. MV_PAR23 = 1 //SÓ REJEITADOS

		TRBF->(DBGoTo(aarr[_nnh,Len(aarr[_nnh])]))

		cClassEnt:=Posicione("SA1",1,xFilial("SA1")+TRBF->CODCLI+TRBF->LOJA,"A1_I_CLABC")
		If cClassEnt = '1'
			cClassEnt:="1-TOP 1 NACIONAL"
		ElseIf cClassEnt = '2'
			cClassEnt:="2-TOP 5 Reg. SP "
		ElseIf cClassEnt = '3'
			cClassEnt:="3-TOP 5 Reg. RS "
		EndIf

		aAdd(_acolec,;
			{AllTrim(TRBF->IMPRIME),;//01
				AllTrim(TRBF->TEMPOPEND),;//02
				aarr[_nnh,A112MAP("Filial Faturamento" )],;//03
				aarr[_nnh,A112MAP("Filial Carregamento")],;//04
				AllTrim(TRBF->NUMPED),;//05
				TRBF->TIPO + " - " + AllTrim(Posicione("ZB4",1,xFilial("ZB4")+TRBF->TIPO,"ZB4_DESCRI")),;//06
				aarr[_nnh,A112MAP("Cliente/Venda"  )],;//07
				aarr[_nnh,A112MAP("Cliente/Remessa")],;//08
				TRANS(TRBF->VALOR,"@E 999,999,999.99"),;//09
				aarr[_nnh,A112MAP("Tipo Entrega")],;//10
				aarr[_nnh,A112MAP("Dt Entrega")],;//11
				If(TRBF->TPFRETE="C",'CIF','FOB'),;//12
				TRANS(TRBF->PESO,"@E 999,999.9999"),;//13
				TRANS(TRBF->DESCONTO,"@E 999,999,999.99"),;//14
				TRBF->OBSCOMER,;//15
				TRBF->MENSANF ,;//16
				cClassEnt    })//17
	EndIf

Next

//Apresenta itlist
If Len(_acolec) > 0

	U_ITListBox( "Pedidos de venda" , _aheaderec , _acolec , .T. , 1 )

Else

	U_ITMsg("Nenhum registro selecionado!","Atenção",,1)

EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS112REC
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Processa a recusa do pedido de venda
Parametros------: oproc - objeto da barra de processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112REC( oproc )

Local _nposi := TRBF->(Recno())
Local _aPeds := {}
Local _acolec := {}
Local _aheaderec := {}
Local _nnh		:= 0
Local _Xnnm		:= 0

TRBF->( DBGoTop() )

//Carrega pedidos selecionados
While TRBF->(!Eof())

	// Somente pedidos selecionados pelo usuario
	If (TRBF->OK == cmarca .And. !linverte) .Or. (TRBF->OK != cmarca .And. linverte)

		aAdd(_aPeds,TRBF->(Recno()))

	EndIf

	TRBF->(DBSkip())

EndDo

//Retorna browse ao pedidos posicionado
TRBF->(DBGoTo(_nposi))

If Len(_aPeds) == 0

	AOMS112RE2(oproc) //Recusa somente pedido posicionado

Else

	//Monta tela de confirmação

	//Monta aheader
	aAdd(_aheaderec,"Impresso")
	aAdd(_aheaderec,"Fil Car")
	aAdd(_aheaderec,"Fil Fat" )
	aAdd(_aheaderec,"Id Pedido" )
	aAdd(_aheaderec,"Cliente/Remessa")
	aAdd(_aheaderec,"Tipo Entrega")
	aAdd(_aheaderec,"Dt Emissão")
	aAdd(_aheaderec,"Dt Carga")
	aAdd(_aheaderec,"Trans Time")
	aAdd(_aheaderec,"Dt Entrega")
	aAdd(_aheaderec,"Tp Frete")
	aAdd(_aheaderec,"Tab Preço")
	aAdd(_aheaderec,"Cond Pgto")
	aAdd(_aheaderec,"Vendedor")
	aAdd(_aheaderec,"Mens NF")
	aAdd(_aheaderec,"Obs")

	//Monta acols
	For _nnh := 1 to Len(aarr)

		If aarr[_nnh][A112MAP(Space(1))] == cmarca

			aAdd(_acolec, {	aarr[_nnh,A112MAP("Impresso")],;
				aarr[_nnh,A112MAP("Filial Faturamento")],;
				aarr[_nnh,A112MAP("Filial Carregamento")],;
				aarr[_nnh,A112MAP("Id Pedido")],;
				aarr[_nnh,A112MAP("Cliente/Remessa")],;
				aarr[_nnh,A112MAP("Tipo Entrega")],;
				aarr[_nnh,A112MAP("Dt Emissão")],;
				aarr[_nnh,A112MAP("Dt Carga")],;
				aarr[_nnh,A112MAP("Trans Time")],;
				aarr[_nnh,A112MAP("Dt Entrega")],;
				aarr[_nnh,A112MAP("Tp Frete")],;
				aarr[_nnh,A112MAP("Tab Preço")],;
				aarr[_nnh,A112MAP("Cond Pgto")],;
				aarr[_nnh,A112MAP("Vendedor")],;
				aarr[_nnh,A112MAP("Mens NF")],;
				aarr[_nnh,A112MAP("Tipo")],;
				aarr[_nnh,A112MAP("Obs")]})
		EndIf

	Next

	//Apresenta itlist
	If Len(_acolec) > 0

		If U_ITListBox( "Recusa de pedidos do portal" , _aheaderec , _acolec , .T. , 1,"Confirma recusa dos pedidos abaixo?" )
			//Solicita motivo da recusa
			cMens1 := ""
			_nopci := 0

			DEFINE FONT oFont NAME "Tahoma" BOLD

			@0,0 TO 320,500 DIALOG oDlg TITLE "Motivo de Recusa de pedidos do portal"

			oTPanel1:= TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,300,160,.T.,.F.)

			@005,010 Say "Motivo de Recusa de múltiplos pedidos"					Of oTPanel1 Pixel FONT oFont

			oTFolder1 := TFolder():New( 050,005,{"Motivo"},,oTPanel1,,,,.T.,,240,090 )

			@ 005,005 Get cMens1 MEMO Size 230,60 when .T. of oTFolder1:aDialogs[1] Pixel

			TButton():New( 145 , 010 , ' Confirma '	, oTPanel1 , {|| _nopci := 1, oDlg:End()	} , 70 , 10 ,,,, .T. )
			TButton():New( 145 , 080 , ' Cancela '	, oTPanel1 , {|| oDlg:END()	} , 70 , 10 ,,,, .T. )

			ACTIVATE MSDIALOG oDlg Centered

			If _nopci == 1

				//Realiza recusa dos pedidos
				For _Xnnm := 1 to Len(_aPeds)


					TRBF->(DBGoTo(_aPeds[_Xnnm]))

					//Recusa pedido sem perguntar motivo
					FWMsgRun(,{|| AOMS112RE2(oproc,cmens1)},"Aguarde...","Recusando pedido " + StrZero(_Xnnm,4) + " de " + StrZero(Len(_aPeds),4) +"...")

				Next

				U_ITListBox( "Recusa de pedidos do portal" , _aheaderec , _acolec , .T. , 1,"Pedidos recusados com sucesso!" )

				//Retorna browse ao pedidos posicionado
				TRBF->(DBGoTo(_nposi))
				FWMsgRun(,{|| AOMS112arq(oproc)},"2 - Aguarde...","Atualizando tela...")

			Else

				U_ITMsg("Processo cancelado pelo usuário!","Atenção",,1)

			EndIf

		Else

			U_ITMsg("Processo cancelado pelo usuário!","Atenção",,1)

		EndIf

	Else

		U_ITMsg("Nenhum registro selecionado!","Atenção",,1)

	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS112RE2
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Processa a recusa do pedido de venda
Parametros------: oproc - objeto da barra de processamento
									_cmotivo - motivo da recusa
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112RE2( oproc, _cmotivo )

Local cTitulo	:= "Recusa de Pedidos Portal"
Local lRetMod2	:= .F. // Retorno da função Modelo2 - .T. Confirmou / .F. Cancelou
Local nLinha	:= 0 , nColuna
Public nOpcx	:= 7
Default _cmotivo := ""

nUsado	:=0
aHeader	:={}
aCols	:={}
cDescr	:= ""
nQtd2UM	:= 0
c2UM	:= ""
nVlrTot	:= 0
nVTot	:= 0

If Empty(_cmotivo)

	// Montagem do aHeader
	aHeader := {	{ "Item"		  		,"ZW_ITEM"			,"@!"					,010,0,"AllwaysTrue()", "","C","","R"},;
		{ "Produto"	  		,"ZW_PRODUTO"		,"@!"					,015,0,"AllwaysTrue()", "","C","","R"},;
		{ "Descrição"	  		,"cDescr" 			,"@!"					,020,0,"AllwaysTrue()", "","C","","R"},;
		{ "Qtd Ven 2 UM"  	,"nQtd2UM" 		,"@e 999,999,999.99"	,014,2,"AllwaysTrue()", "","C","","R"},;
		{ "Segunda UM"	   	,"c2UM"			,"@!"					,002,0,"AllwaysTrue()", "","C","","R"},;
		{ "Quantidade"		,"ZW_QTDVEN"		,"@e 999,999,999.99"	,014,2,"AllwaysTrue()", "","C","","R"},;
		{ "Unidade"		   	,"ZW_UM"			,"@!"					,002,0,"AllwaysTrue()", "","C","","R"},;
		{ "Prc Unitario" 		,"ZW_PRCVEN"		,"@e 9,999,999.9999"	,014,4,"AllwaysTrue()", "","C","","R"},;
		{ "Vlr.Total "		,"nVlrTot"			,"@e 999,999,999.99"	,014,2,"AllwaysTrue()", "","C","","R"},;
		{ "Blq. Preço "		,"ZW_BLOPRC"		,"@!"					,001,0,"AllwaysTrue()", "","C","","R"} }

	//Locka registros
	If !( AOMS112LO( SubStr( TRBF->FILIAL , 1 , 2 ), TRBF->NUMPED ) )

		Return

	EndIf

	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	If SZW->( DBSeek( SubStr( TRBF->FILIAL , 1 , 2 ) + TRBF->NUMPED ) )

		While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == SubStr( TRBF->FILIAL , 1 , 2 ) + TRBF->NUMPED

			aAdd( aCols , Array( Len(aHeader) + 1 ) )
			nLinha++

			cDescr	:= GetAdvFVal( "SB1" , "B1_I_DESCD"	, xFilial("SB1") + AllTrim( SZW->ZW_PRODUTO )	, 1 , "" )
			nFatConv:= GetAdvFVal( "SB1" , "B1_CONV"	, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )
			cTpConv := GetAdvFVal( "SB1" , "B1_TIPCONV"	, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )
			nNewFat := GetAdvFVal( "SB1" , "B1_I_FATCO"	, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )

			If cTpConv == "M"
				nQtd2UM := IIf( nFatConv == 0 , nNewFat * SZW->ZW_QTDVEN	, nFatConv * SZW->ZW_QTDVEN	)
			Else
				nQtd2UM := IIf( nFatConv == 0 , SZW->ZW_QTDVEN / nNewFat	, SZW->ZW_QTDVEN / nFatConv	)
			EndIf

			c2UM	:= GetAdvFVal( "SB1" , "B1_SEGUM"	, xFilial("SB1") + AllTrim( SZW->ZW_PRODUTO )	, 1 , "" )
			nVlrTot := SZW->ZW_QTDVEN * SZW->ZW_PRCVEN
			nVtot	+= nVlrTot

			For nColuna := 1 to Len(aHeader)
				aCols[nLinha][nColuna] := &(aHeader[nColuna][2])
			Next nColuna

			aCols[nLinha][Len(aHeader)+1] := .F. // Linha não deletada

			SZW->( DBSkip() )
		EndDo

	EndIf

	cFli		:= Space(020)
	cFilPro		:= Space(040)
	cTipPed		:= Space(015)
	cNumPed		:= Space(025)
	cCliente	:= Space(006)
	cNomCli		:= Space(060)
	cLojaCli	:= Space(004)
	cGrpCli		:= Space(030)
	cCond		:= Space(050)
	cVend1		:= Space(006)
	cNmVend1	:= Space(040)
	cVend2		:= Space(006)
	cNmVend2	:= Space(040)
	cPedCli		:= Space(009)
	dDtEnt		:= CtoD("")
	cTipoAg		:= Space(10)
	cHrEnt		:= Space(005)
	cSha		:= Space(014)
	cTipFre		:= Space(010)
	cTipCar		:= Space(015)
	cQtdCha		:= Space(003)
	cHrDes		:= Space(005)
	nCusDes		:= 0
	cObsCom		:= Space(300)
	cObsNF		:= Space(300)

	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( SubStr( TRBF->FILIAL , 1 , 2 ) + TRBF->NUMPED ) )

	dDtEnt		:= SZW->ZW_FECENT
	_laltera := .T.

	If SZW->ZW_I_AGEND == 'P'
		If month(date()) != 12
			dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+1)))+"0101")-1
		Else
			dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+2)))+"0101")-1
		EndIf

		_laltera := .F.
	EndIf

	If SZW->ZW_I_AGEND $ 'I/O'//I=Imediata //O=Agendada pelo Op.Log.
		_cFilCarreg := SZW->ZW_FILIAL
		If !Empty(SZW->ZW_FILPRO) .And. !(AllTrim(SZW->ZW_FILPRO)=='0')
			_cFilCarreg := SZW->ZW_FILPRO
		EndIf

		//cTipoAg	:= SZW->ZW_I_AGEND+" - IMEDIATO"
		dDtEnt      := SZW->ZW_FECENT
		_laltera := .F.

	EndIf

	cTipoAg:=SZW->ZW_I_AGEND+" - "+(U_TipoEntrega(SZW->ZW_I_AGEND))
	
	// aC[n,1] = Nome da Variavel Ex.:"cCliente"
	// aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aC[n,3] = Titulo do Campo
	// aC[n,4] = Picture
	// aC[n,5] = Validacao
	// aC[n,6] = F3
	// aC[n,7] = Se campo e' editavel .T. se nao .F.

	aC := {	{ "cFli"	,{015,003} 		,"Filial                   " 	  	,"@!"   				,	,		,.F.	},;
		{ "cFilPro" 	,{015,203} 		,"Filial Carregamento   "         	,"@!"   				,   ,       ,.F.	},;
		{ "cTipPed"		,{030,003} 		,"Tipo Pedido       " 	  			,"@!"   				,	,		,.F.	},;
		{ "cNumPed"		,{030,203} 		,"Num. Pedido " 	  				,"@!"   				,	,		,.F.	},;
		{ "cCliente"	,{045,003}		,"Cliente/Remessa" 		 			,"@!"   				,	,		,.F.	},;
		{ "cLojaCli"	,{045,085}		,"Loja   "							,"@!"   				,	,		,.F.	},;
		{ "cNomCli"		,{045,140} 		,"Nome Cliente/Remessa"				,"@!"   				,	,		,.F.	},;
		{ "cGrpCli"		,{060,003} 		,"Grupo Cliente/Rem."				,"@!"   				,	,		,.F.	},;
		{ "cCond"		,{060,285}		,"Cond. Pagto" 						,"@!"   				,	,		,.F.	},;
		{ "cVend1"		,{075,003}		,"Vendedor 1       "  				,"@!"   				,	,		,.F.	},;
		{ "cNmVend1"	,{075,140}		,"Nome Vendedor 1" 					,"@!"   				,	,		,.F.	},;
		{ "nVTot"		,{075,500}		,"Valor Total   " 					,"@e 999,999,999.99"	,	,		,.F.	},;
		{ "cVend2"		,{090,003}		,"Vendedor 2       "  				,"@!"   				,	,		,.F.	},;
		{ "cNmVend2"	,{090,140}		,"Nome Vendedor 2" 					,"@!"   				,	,		,.F.	},;
		{ "cPedCli" 	,{105,003} 		,"Pedido Cliente/Remessa    "		,"@!"   				,	,		,.F.	},;
		{ "cTipoAg"		,{030,500}		,"Tipo Agendamento"					,"@!"   				,	,		,.F.	},;
		{ "dDtEnt"		,{015,470}		,"Data Entrega          "			,"@!"   				,	,		,_laltera	},;
		{ "cHrEnt"		,{015,570}		,"Hora Entrega   "					,"@!"   				,	,		,.F.	},;
		{ "cSha"		,{105,325}		,"Senha                "			,"@!"   				,	,		,.F.	},;
		{ "cTipFre"	 	,{105,500} 		,"Tipo Frete    "					,"@!"   				,	,		,.F.	},;
		{ "cTipCar"		,{120,003} 		,"Tipo de Carga     "				,"@!"   				,	,		,.F.	},;
		{ "cQtdCha"		,{120,140} 		,"Qtd. Chapa           "			,"@!"   				,	,		,.F.	},;
		{ "cHrDes"		,{120,245} 		,"Hora Descarga"					,"@!"   				,	,		,.F.	},;
		{ "nCusDes"		,{120,325} 		,"Custo Descarga"					,"@e 999,999,999.99"	,	,		,.F.	},;
		{ "cObsCom"		,{135,003} 		,"Obs. Comercial  "					,"@!"					,	,		,.F.	},;
		{ "cObsNf"		,{150,003} 		,"Mensagem NF    "					,"@!"					,	,		,.F.	} }


	// Array com descricao dos campos do Rodape do Modelo 2
	// aR[n,1] = Nome da Variavel Ex.:"cCliente"
	// aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aR[n,3] = Titulo do Campo
	// aR[n,4] = Picture
	// aR[n,5] = Validacao
	// aR[n,6] = F3
	// aR[n,7] = Se campo e' editavel .T. se nao .F.
	aR := {}

	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	If SZW->( DBSeek( SubStr( TRBF->FILIAL , 1 , 2 ) + TRBF->NUMPED ) )

		cFli		:= Left( SubStr( TRBF->FILIAL , 1 , 2 ) +" - "+ GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(TRBF->FILIAL,1,2),1,""),25 )
		cFilPro		:= SubStr( TRBF->FILPRO , 1 , 2 ) +" - "+ GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(TRBF->FILPRO,1,2),1,"")
		cTipPed		:= SubStr( TRBF->TIPO +" - "+ GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+TRBF->TIPO,1,"") , 1 , 25 )
		cNumPed  	:= TRBF->NUMPED
		cCliente 	:= SZW->ZW_CLIENTE
		cLojaCli 	:= SZW->ZW_LOJACLI
		cNomCli 	:= GetAdvFVal( "SA1" , "A1_NOME"	, xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI , 1 , "" )
		cGrpCli		:= GetAdvFVal( "SA1" , "A1_GRPVEN"	, xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI , 1 , "" ) +" - "+ GetAdvFVal( "SA1" , "A1_I_NGRPC" , xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI , 1 , "" )
		cCond		:= AOMS1125()
		cVend1	 	:= SZW->ZW_VEND1
		cNmVend1 	:= GetAdvFVal( "SA3" , "A3_NOME" , xFilial("SA3") + SZW->ZW_VEND1 , 1 , "" )
		cVend2   	:= SZW->ZW_VEND2
		cNmVend2 	:= GetAdvFVal( "SA3" , "A3_NOME" , xFilial("SA3") + SZW->ZW_VEND2 , 1 , "" )
		nVTot 		:= nVTot
		cPedCli		:= SZW->ZW_PEDCLI

		cHrEnt		:= SZW->ZW_HOREN
		cSha		:= SZW->ZW_SENHA
		cTipFre		:= If( SZW->ZW_TPFRETE == 'C' , SZW->ZW_TPFRETE	+" - CIF"			, SZW->ZW_TPFRETE	+" - FOB"		)
		_cchep 		:= Posicione("SA1",1,xFilial("SA1")+ccliente+cLojaCli,"A1_I_CCHEP")
		cTipCar		:= If( !Empty(_cchep) , "1 - Paletizada" , "2 - Batida" )
		cQtdCha		:= SZW->ZW_CHAPA
		cHrDes		:= SZW->ZW_HORDES
		nCusDes		:= SZW->ZW_CUSDES
		cObsCom		:= SZW->ZW_OBSCOM
		cObsNF		:= SZW->ZW_MENNOTA
		aCGD		:= { 350 , 06 , 26 , 74 } // Array com coordenadas da GetDados no modelo2

		// Chamada da Modelo2
		lRetMod2 := Modelo2( cTitulo , aC , aR , aCGD , nOpcx ,,,,,, 9999 ,,, .T. )

		If lRetMod2

			cMens1 := ""

			DEFINE FONT oFont NAME "Tahoma" BOLD

			@0,0 TO 320,500 DIALOG oDlg TITLE "Recusa de pedido do portal"

			oTPanel1:= TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,300,160,.T.,.F.)

			@005,010 Say "Motivo de Recusa"								Of oTPanel1 Pixel FONT oFont
			@020,010 Say "Pedido........: "+ cNumPed					Of oTPanel1 Pixel
			@020,100 Say "Cliente/Remessa.......: "+ cCliente +" - "+ cLojaCli	Of oTPanel1 Pixel
			@035,010 Say "Nome Cliente/Remessa..: "+ cNomCli					Of oTPanel1 Pixel

			oTFolder1 := TFolder():New( 050,005,{"Motivo"},,oTPanel1,,,,.T.,,240,090 )

			@ 005,005 Get cMens1 MEMO Size 230,60 when .T. of oTFolder1:aDialogs[1] Pixel

			TButton():New( 145 , 010 , ' Confirma '	, oTPanel1 , {|| FWMsgRun(,{|oproc| AOMS112GRC(SubStr( TRBF->FILIAL , 1 , 2 ), TRBF->NUMPED)},"Aguarde...","Gravando recusa..."), oDlg:End()	} , 70 , 10 ,,,, .T. )
			TButton():New( 145 , 080 , ' Cancela '	, oTPanel1 , {|| oDlg:END()	} , 70 , 10 ,,,, .T. )

			ACTIVATE MSDIALOG oDlg Centered

		EndIf

	Else

		U_ITMsg(  'Não foi possível posicionar no pedido!' , 'Atenção!',,1)

	EndIf

Else

	//Execução múltipla
	cMens1 := _cmotivo

	AOMS112GRC(SubStr( TRBF->FILIAL , 1 , 2 ), TRBF->NUMPED)

EndIf

AOMS112UN(SubStr( TRBF->FILIAL , 1 , 2 ), TRBF->NUMPED )

Return

/*
===============================================================================================================================
Programa--------: AOMS112GRC
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Grava as informações da recusa do pedido de venda
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112GRC(cFilPed, nIDPED, cOrigem, cMot)

Local cEmail   := ""
Local cCliente := ""
Local lEnvia   := .F.

Default cOrigem := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]

If !Empty(AllTrim(cMot))
	cMens1 := cMot
EndIf

DBSelectArea("SZW")
SZW->( DBSetOrder(1) )
If SZW->( DBSeek( AllTrim(cFilPed) + AllTrim(nIDPED) ) )

	While !(Eof()) .And. AllTrim(SZW->ZW_FILIAL) + AllTrim(SZW->ZW_IDPED) == AllTrim(cFilPed)  + AllTrim(nIDPED)

		RecLock( "SZW" , .F. )

		SZW->ZW_STATUS := "R"
		SZW->ZW_MOTREC := cMens1
		SZW->ZW_MOTREP := cMens1
		SZW->ZW_USRREC := cOrigem
		SZW->ZW_DTREC  := Date()
		SZW->ZW_HRREC  := Time()

		SZW->( MSUnLock() )

		cCliente	:= SZW->ZW_CLIENTE +" - "+ SZW->ZW_LOJACLI +" - "+ GetAdvFVal( "SA1" , "A1_NOME" , xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI , 1 , "" )
		cEmail		:= GetAdvFVal( "SA3" , "A3_EMAIL" , xFilial("SA3") + SZW->ZW_VEND1 , 1 , "" )
		lEnvia		:= .T.
		SZW->( DBSkip() )
	EndDo

	If lEnvia
		DBSelectArea("SZW")
		SZW->( DBSetOrder(1) )
		SZW->( DBSeek( AllTrim(cFilPed) + AllTrim(nIDPED) ) )

		cMsg := '<table width="75%" border="1"> '
		cMsg += '  <tr>  '
		cMsg += '    <td bordercolor="#000000" bgcolor="#778899" align="center"><font color="#FFFFFF">AVISO DE RECUSA DE PEDIDO</font></td> '
		cMsg += '  </tr>  '
		cMsg += '</table>  '
		cMsg += '<BR> '
		cMsg += '<table width="75%" border="1"> '
		cMsg += '  <tr> '
		cMsg += '    <td><b>Pedido: </b>'+ AllTrim(nIDPED) + ' Dt.Inclusão: ' +   DToC(SZW->ZW_EMISSAO) + ' HH Inclusão: ' + SZW->ZW_HORAINC + ' </td>  '
		cMsg += '  </tr>  '
		cMsg += '</table> '
		cMsg += '<table width="75%" border="1"> '
		cMsg += '  <tr>  '
		cMsg += '    <td><b>Cliente: </b>'+ AllTrim(cCliente) +'</td>  '
		cMsg += '  </tr> '
		cMsg += '</table>  '
		cMsg += '<table width="75%" border="1"> '
		cMsg += '  <tr> '
		cMsg += '    <td><b>Motivo: </b> </td>  '
		cMsg += '  </tr> '
		cMsg += '</table>  '
		cMsg += '<table width="75%" border="1"> '
		cMsg += '  <tr> '

		I		:= 1
		lRetMen	:= .T.

		While lRetMen

			If I < Len( cMens1 )
				cMsg +='   <td>'+ SubStr(cMens1,I,254) +' </td> '
			Else
				lRetMen := .F.
			EndIf

			I += 254

		EndDo

		cMsg +='  </tr> '
		cMsg +='</table>  '

		AOMS112EN( cMsg , "Recusa Pedido do Portal - Filial " + AllTrim(SZW->ZW_FILIAL) + " Pedido " + AllTrim(nIDPED) + " Cliente/Remessa " + AllTrim(cCliente) , cEmail )
	EndIf
EndIf

Return( .T. )

/*
===============================================================================================================================
Programa--------: AOMS112EN
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Processa o envio de mensagens
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112EN( cMensagem , cTitulo , cEmail )

nInd		:= 0
lResult		:= .F.
_cArq		:= ''
lRelauth	:= .T.

// Tenta conexao com o servidor de E-Mail
CONNECT SMTP                    ;
SERVER       GetMV("MV_RElseRV");      // Nome do servidor de e-mail = smtp.bra.terra.com.br
ACCOUNT 	 GetMV("MV_RELACNT");      // Nome da conta a ser usada no e-mail = fulano
PASSWORD 	 GetMV("MV_RELPSW") ;      // Senha = senha
RESULT       lResult                   // Resultado da tentativa de conexão

If lRelauth
	lRet := Mailauth(GetMV("MV_RELACNT"),GetMV("MV_RELPSW"))
Else
	lRet := .T.
EndIf

If lResult

	SEND MAIL FROM GetMV("MV_RELACNT") TO cEmail SUBJECT cTitulo BODY cMensagem RESULT lResult

EndIf

// Finaliza conexao com o servidor de E-Mail
DISCONNECT SMTP SERVER

Return( lResult )

/* 
===============================================================================================================================
Programa--------: AOMS112AF
Autor-----------: Josué Danich Prestes
Data da Criacao-: 21/03/2019
Descrição-------: Alteração múltipla de filiais
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112AF()

Local _nposi := TRBF->(Recno())
Local _aPeds := {}
Local _acolec := {}
Local _aheaderec := {}
Local _nnh		:= 0
Local _nnm		:= 0
Private cfilfat := Space(30)
Private cfilcrg := Space(30)


TRBF->( DBGoTop() )

//Carrega pedidos selecionados
While TRBF->(!Eof())

	// Somente pedidos selecionados pelo usuario
	If (TRBF->OK == cmarca .And. !linverte) .Or. (TRBF->OK != cmarca .And. linverte)

		aAdd(_aPeds,TRBF->(Recno()))

	EndIf

	TRBF->(DBSkip())

EndDo

//Retorna browse ao pedidos posicionado
TRBF->(DBGoTo(_nposi))

If Len(_aPeds) == 0

	U_ITMsg("Nenhum pedido selecionado","Atenção","Selecione pedidos ou altere as filiais diretamente na tela",1)

Else

	//Monta tela de confirmação

	//Monta aheader
	aAdd(_aheaderec,"Impresso")
	aAdd(_aheaderec,"Fil Car")
	aAdd(_aheaderec,"Fil Fat" )
	aAdd(_aheaderec,"Id Pedido" )
	aAdd(_aheaderec,"Cliente/Remessa")
	aAdd(_aheaderec,"Tipo Entrega")
	aAdd(_aheaderec,"Dt Emissão")
	aAdd(_aheaderec,"Dt Carga")
	aAdd(_aheaderec,"Trans Time")
	aAdd(_aheaderec,"Dt Entrega")
	aAdd(_aheaderec,"Tp Frete")
	aAdd(_aheaderec,"Tab Preço")
	aAdd(_aheaderec,"Cond Pgto")
	aAdd(_aheaderec,"Vendedor")
	aAdd(_aheaderec,"Mens NF")
	aAdd(_aheaderec,"Obs")

	//Monta acols
	For _nnh := 1 to Len(aarr)

		If aarr[_nnh][1] == cmarca

			aAdd(_acolec, {	 aarr[_nnh,A112MAP("Impresso")],;
				aarr[_nnh,A112MAP("Filial Faturamento") ],;
				aarr[_nnh,A112MAP("Filial Carregamento")],;
				aarr[_nnh,A112MAP("Id Pedido")],;
				aarr[_nnh,A112MAP("Cliente/Remessa")],;
				aarr[_nnh,A112MAP("Tipo Entrega")],;
				aarr[_nnh,A112MAP("Dt Emissão")],;
				aarr[_nnh,A112MAP("Dt Carga")],;
				aarr[_nnh,A112MAP("Trans Time")],;
				aarr[_nnh,A112MAP("Dt Entrega")],;
				aarr[_nnh,A112MAP("Tp Frete")],;
				aarr[_nnh,A112MAP("Tab Preço")],;
				aarr[_nnh,A112MAP("Cond Pgto")],;
				aarr[_nnh,A112MAP("Vendedor")],;
				aarr[_nnh,A112MAP("Mens NF")],;
				aarr[_nnh,A112MAP("Obs")]})
		EndIf

	Next

	//Apresenta itlist
	If Len(_acolec) > 0

		If U_ITListBox( "Alteração de filiais de pedidos" , _aheaderec , _acolec , .T. , 1,"Confirma alteração de filiais dos pedidos abaixo?" )

			//Solicita filiais
			cMens1 := ""
			_nopci := 0
			cfilcrg := aarr[01,A112MAP("Filial Carregamento")]
			cfilfat := aarr[01,A112MAP("Filial Faturamento")]

			DEFINE FONT oFont NAME "Tahoma" BOLD

			@0,0 TO 320,500 DIALOG oDlg TITLE "Alteração de filiais de pedidos do portal"

			oTPanel1:= TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,300,160,.T.,.F.)

			@ 005,010 Say "Filial de Faturamento:"	Of oTPanel1 Pixel FONT oFont
			@ 005,090 Get cfilfat valid AOMS112F2() when .T. of oTPanel1 Pixel

			@ 035,010 Say "Filial de Carregamento:"		Of oTPanel1 Pixel FONT oFont
			@ 035,090 Get cfilcrg valid AOMS112F2() when .T. of oTPanel1 Pixel


			TButton():New( 145 , 010 , ' Confirma '	, oTPanel1 , {|| _nopci := 1, oDlg:End()	} , 70 , 10 ,,,, .T. )
			TButton():New( 145 , 080 , ' Cancela '	, oTPanel1 , {|| oDlg:END()	} , 70 , 10 ,,,, .T. )

			ACTIVATE MSDIALOG oDlg Centered

			If _nopci == 1

				//Valida filial de faturamento em branco
				If Empty(cfilfat)
					TRBF->(DBGoTo(_nposi))
					U_ITMsg("Filial de faturamento não pode ficar em branco!","Atenção",,1)
					Return
				EndIf

				_acolec2 := {}

				//Realiza alteração de pedidos
				For _nnm := 1 to Len(_aPeds)

					BEGIN TRANSACTION
						TRBF->(DBGoTo(_aPeds[_nnm]))

						_cfilul := TRBF->FILIAL
						_numul  := TRBF->NUMPED

						RecLock("TRBF",.F.)
						TRBF->FILIAL := cfilfat
						TRBF->FILPRO := cfilcrg
						TRBF->(MSUnLock())

						_acolec[_nnm][1] := cfilfat
						_acolec[_nnm][2] := cfilcrg

						SZW->(DBSetOrder(1))
						If SZW->(DBSeek(SubStr(_cfilul,1,2)+_numul))

							If  !( AOMS112LO( SubStr(_cfilul,1,2), _numul,.F. ) )

								aAdd(_acolec2,{_acolec[_nnm][1],_acolec[_nnm][2],_acolec[_nnm][3],_acolec[_nnm][4],"Pedido em uso!"})
								Disarmtransaction()

							Else

								SZW->(DBSeek(SubStr(_cfilul,1,2)+_numul))
								While SZW->ZW_FILIAL == SubStr(_cfilul,1,2) .And. AllTrim(SZW->ZW_IDPED) == AllTrim(_numul)

									RecLock("SZW",.F.)
									SZW->ZW_FILIAL := LEFT(cfilfat,2)
									SZW->ZW_FILPRO := LEFT(cfilcrg,2)
									SZW->(MSUnLock())
									SZW->(DBSkip())

								EndDo

								AOMS112UN( SubStr(TRBF->FILIAL,1,2), _numul )

								aAdd(_acolec2,{_acolec[_nnm][1],_acolec[_nnm][2],_acolec[_nnm][3],_acolec[_nnm][4],"Filiais alteradas com sucesso"})

							EndIf

						Else

							Disarmtransaction()
							_acolec[_nnm][1] := TRBF->FILIAL
							_acolec[_nnm][2] := TRBF->FILPRO
							aAdd(_acolec2,{_acolec[_nnm][1],_acolec[_nnm][2],_acolec[_nnm][3],_acolec[_nnm][4],"Falha na alteração de filiais"})

						EndIf

					END TRANSACTION

				Next

				//Monta novo aheader
				_aheaderec := {}
				//Monta aheader
				aAdd(_aheaderec,"Fil Car")
				aAdd(_aheaderec,"Fil Fat" )
				aAdd(_aheaderec,"Id Pedido" )
				aAdd(_aheaderec,"Cliente/Remessa")
				aAdd(_aheaderec,"Resultado")

				U_ITListBox( "Alteração de filiais de pedidos do portal" , _aheaderec , _acolec2 , .T. , 1,"Alteração de filiais de pedidos do portal realizada com sucesso!" )

				//atualiza a tela
				FWMsgRun(,{|oproc| AOMS112arq(oproc)},"3 - Aguarde...","Atualizando tela...")

			Else

				U_ITMsg("Processo cancelado pelo usuário!","Atenção",,1)

			EndIf

		Else

			U_ITMsg("Processo cancelado pelo usuário!","Atenção",,1)

		EndIf

	Else

		U_ITMsg("Nenhum registro selecionado!","Atenção",,1)

	EndIf

EndIf

//Retorna browse ao pedidos posicionado
TRBF->(DBGoTo(_nposi))

Return

/*
===============================================================================================================================
Programa--------: AOMS112F2
Autor-----------: Josué Danich Prestes
Data da Criacao-: 21/03/2019
Descrição-------: Validação de filial
Parametros------: Nenhum
Retorno---------: lret - validação sim ou não
===============================================================================================================================
*/
Static Function AOMS112F2()

Local lret := .T.
Local cfildes2 := ""
Local cfildes := ""

If !Empty(cfilcrg)

	cFilDes2:= GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+LEFT(cfilcrg,2),1,"")
	If Empty(cFilDes2)
		U_ITMsg("Filial de carregamento nao cadastrada",'Atenção',,1)
		Return .F.
	EndIf

EndIf

If !Empty(cfilfat)

	cFilDes:= GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+LEFT(cfilfat,2),1,"")
	If Empty(cFilDes)
		U_ITMsg("Filial de faturamento nao cadastrada",'Atenção',,1)
		Return .F.
	EndIf

	_cFilSalva:= cFilAnt
	cFilAnt   := LEFT(AllTrim(cfilfat),2)
	If AllTrim(SuperGetMV("IT_FATNF",.T.,"N")) == "N"
		U_ITMsg("Filial "+cfilfat+" nao é troca nota de Faturamento (IT_FATNF)",'Atenção',,1)
		cFilAnt  := _cFilSalva
		Return .F.
	EndIf

	If !Empty(cfilcrg)
		cFilAnt:=LEFT(cfilcrg,2)
		If AllTrim(SuperGetMV("IT_PRONF",.T.,"N")) == "N"
			U_ITMsg("Filial "+AllTrim(cfilcrg)+" nao é troca nota de Carregamento (IT_PRONF)",'Atenção',,1)
			cFilAnt  := _cFilSalva
			Return .F.
		EndIf
	EndIf

	cFilAnt  := _cFilSalva

	If lRet .And. !Empty(cfilcrg)                            //Fil Carregamento, Fil Faturamento
		lRet:=U_AOM112Val( 'VAL_GRUPO' , left(cfilcrg,2) , left(cfilfat,2) )
	EndIf

EndIf

If !Empty(cFilDes)
	cfilfat:= LEFT(LEFT(cfilfat,2)+" - "+cFilDes,40)
EndIf
If !Empty(cFilDes2)
	cfilcrg:= LEFT(LEFT(cfilcrg,2)+" - "+cFilDes2,40)
EndIf

Return lret

/*
===============================================================================================================================
Programa--------:  AOMS112EFI
Autor-----------: Josué Danich Prestes
Data da Criacao-: 22/03/2019
Descrição-------: Chamada de efetivação dos pedidos de vendas do portal
Parametros------: oproc - objeto da barra de processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112EFI(oproc)

Local _nposi := TRBF->(Recno())
Local _aPeds := {}
Local _nnm		:= 0
Private _lefetivado := .F.
Private _aResults := {}
Private _nni := 0
Private _ntot := 0


TRBF->( DBGoTop() )

//Carrega pedidos selecionados
While TRBF->(!Eof())

	// Somente pedidos selecionados pelo usuario
	If (TRBF->OK == cmarca .And. !linverte) .Or. (TRBF->OK != cmarca .And. linverte)

		aAdd(_aPeds,TRBF->(Recno()))

	EndIf

	TRBF->(DBSkip())

EndDo

//Retorna browse ao pedidos posicionado
TRBF->(DBGoTo(_nposi))

If Len(_aPeds) == 0

	U_ITMsg("Nenhum pedido selecionado","Atenção","Selecione ao menos um pedido para efetivar",1)

Else

	aSort(_aPeds)
	If Len(_aPeds) > 0

		_lefetivado := .T.
		_aResults := {}
		//Realiza efetivação dos pedidos
		For _nnm := 1 to Len(_aPeds)

			TRBF->(DBGoTo(_aPeds[_nnm]))
			_ntot := Len(_aPeds)
			_nni := _nnm
			FWMsgRun(,{|oproc| AOMS112EFE(TRBF->NUMPED , LEFT(TRBF->FILIAL,2),.T.)},;
				"Aguarde...","Efetivando pedido " + StrZero(_nnm,4) + " de " + StrZero(Len(_aPeds),4) +"...")


		Next

		If Len(_aResults) > 0

			_aCab:={' ','Filial','Pedido','Cliente/Remessa','Resultado / Erros',"Complemento do Resultado / Erros"}
			For _nnm := 1 TO Len(_aResults)
				If Len(_aResults[_nnm]) < 6
					ASize( _aResults[_nnm] , 6 )
					_aResults[_nnm,6]:=" "
				EndIf
			Next

			//Apresenta resultados
			U_ITListBox( "Efetivação de pedidos do portal" ,_aCab , _aResults , .T. , 1,"Resultado dos processamentos" )

		Else

			U_ITMsg("Nenhum pedido efetivado!","Atenção",,1)

			_lefetivado := .F.

		EndIf

		If _lefetivado

			FWMsgRun(,{|oproc| AOMS112arq(oproc)},"4 - Aguarde...","Atualizando tela...") //remonta tela

		EndIf

	Else

		U_ITMsg("Nenhum registro selecionado!","Atenção",,1)

	EndIf

EndIf

//Retorna browse ao pedidos posicionado
TRBF->(DBGoTo(_nposi))

Return

/*
===============================================================================================================================
Programa--------: AOMS112EFE
Autor-----------: Alexandre Villar
Data da Criacao-: 14/02/2014
Descrição-------: Efetivação dos pedidos de vendas do portal
Parametros------: cNumPed - Número do pedido de venda do portal
----------------: cFilAux - Filial do pedido de venda
									_lAutoref - execução de múltiplos pedidos
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112EFE(cNumPed , cFilAux, _lAutoref ,_lTela)

Local aArea	    := FWGetArea()
Local lProcOk   := .T. //Variável de Controle de Erros de Processamento
Local _cOper    := "01"
Local _cItensPM := ""
Local _cItensMA := ""
Local _cDetPM   := ""
Local _cDetMA   := ""

Private _aRet := {}

Default _lAutoref := .F.
Default _lTela := .T.

//1-Valida se o Pedido deve ser Efetivado com a Nova Regra de WF de Aprovação de Preço
If _lTela
	FWMsgRun(, {|| lProcOk:= AOMS112WF(cFilAux,cNumPed) }, "Aguarde!" , "1-Validando WF de Aprovação de Preço " + cNumPed	 )
Else
	lProcOk:= AOMS112WF(cFilAux,cNumPed)
EndIf

//Valida se o Cliente pode usar Tipo de Frete FOB
If lProcOk
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( cFilAux + cNumPed ) )
	_lFob := Posicione("SA1",1,xFilial("SA1") + SZW->ZW_CLIENTE + SZW->ZW_LOJACLI ,"A1_I_FOB")
	If SZW->ZW_TPFRETE == "F"
		If !_lFob

			If _lAutoref
				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),"Para este Cliente/Remessa não é permitdo o Tipo de Frete = FOB. Necessário ajuste no cadastro desse cliente antes da efetivação."})
			Else
				U_ITMsg("Para este Cliente/Remessa " + SZW->ZW_CLIENTE + " Loja: " + SZW->ZW_LOJACLI + " - " + AllTrim(SA1->A1_NOME) + " não é permitdo o Tipo de Frete = FOB. Necessário ajuste no cadastro desse Cliente/Remessa antes da efetivação. Pedido: "+cNumPed,"Atenção!" , ,1 )
			EndIf

			lProcOk := .F.
		EndIf
	EndIf
EndIf

// Inclusão de Tratamentos para Unidade Frisia = Filial 93
SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )
If SZW->ZW_FILPRO $ "93" .Or. SZW->ZW_FILIAL $ "93" //.And. SZW->ZW_TIPO == "01"
	U_AOMS112Q(SZW->ZW_FILIAL , cNumPed ,SZW->ZW_FILPRO)
EndIf

//2-Valida se o Cliente desse Pedido possui pedido(s) de Bonificacao sem aprovação
SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )
If lProcOk .And. AllTrim(SZW->ZW_TIPO) <> '10'

	SA1->(DBSetOrder(1))
	SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))
	_cPSB:=""

	If _lTela
		FWMsgRun(, {|| lProcOk := AOM112BoniApro(SZW->ZW_CLIENTE,SZW->ZW_LOJACLI,@_cPSB) }, "Aguarde!" , "2-Validando Bonificacao do pedido " + cNumPed	 )
	Else
		lProcOk := AOM112BoniApro(SZW->ZW_CLIENTE,SZW->ZW_LOJACLI,@_cPSB)
	EndIf
	If !lProcOk
		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,cNumPed,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),"O Cliente/Remessa desse Pedido possui pedido(s) de Bonificacao sem aprovação: "+_cPSB})
	EndIf

EndIf

//3-Validando Limites de Crédito do pedido
If lProcOk
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( cFilAux + cNumPed ) )

	SA1->(DBSetOrder(1))
	SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

	//-- Validação do Limite de Crédito do Cliente --//
	If lProcOk .And. AllTrim(SZW->ZW_TIPO) != '10' .And. !SZW->ZW_STATUS $ "E/C"

		If _lTela
			FWMsgRun(, {|| lProcOk := AOMS112LCR( cNumPed , cFilAux,_lAutoref ) }, "Aguarde!" , "3-Validando Limites de Crédito do pedido " + cNumPed	)
		Else
			lProcOk := AOMS112LCR( cNumPed , cFilAux,_lAutoref )
		EndIf

	EndIf
EndIf


//4-Valida Itens do pedido que a qtd não é multipla a Qt. Pallet do Produto
SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )

SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

If lProcOk .And. SZW->ZW_FILIAL = '90' //.And. !AOMS112PM(cFilAux,cNumPed,@_cItensPM,@_cDetPM)

	If _lTela
		FWMsgRun(, {|| lProcOk := AOMS112PM(cFilAux,cNumPed,@_cItensPM,@_cDetPM) }, "Aguarde!" , "4-Valida Itens do pedido que a qtd não é multipla a Qt. Pallet " + cNumPed	 )
	Else
		lProcOk := AOMS112PM(cFilAux,cNumPed,@_cItensPM,@_cDetPM)
	EndIf

	If !lProcOk
		If _lautoref
			aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,cNumPed,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),'O(s) Item(ns): '+_cItensPM+ " do Pedido possuem Qtd de venda não permitida! Atribua a Qtd do pedido um multiplo de CX do Cadastro do Produto. " + CRLF + _cDetPM})
		Else
			U_ITMsg("Pedido ["+ AllTrim(cNumPed) +"] possui o(s) seguinte(s) item(ns): "+_cItensPM + " com Qtd de venda não permitida!" ,"Validação de Produto","Atribua a Qtd do pedido um multiplo de CX do Cadastro do Produto. " ,1)
			MsgAlert(_cDetPM,"Detalhes")
		EndIf
	EndIf

EndIf

//Valida peso acima de 22.000 somente para Produto Matinais 
SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )

SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

If lProcOk .And. AOMS112MA(cFilAux,cNumPed,@_cItensMA,@_cDetMA)

	If _lautoref
		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,cNumPed,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),;
			"Para o(s) Item(ns): " + _cItensMA + " do Pedido que são Matinais não é permitido que possuam peso Superior a " ;
			+ AllTrim(Str(_nPesoMat)) + " kg! Troque para o armazem " ;
			+ AllTrim(_cArmazMat) + ". " + CRLF + _cDetMA})
	Else
		U_ITMsg("Para o(s) Item(ns): " + _cItensMA + " do Pedido ["+ AllTrim(cNumPed) ;
			+"] que são Matinais não é permitido que possuam peso Superior a " + AllTrim(Str(_nPesoMat)) + " kg!" ,;
			"Validação de Produto","Troque para o armazem " + AllTrim(_cArmazMat) + ". ",1)

		MsgAlert(_cDetMA,"Detalhes")
	EndIf

	lProcOk := .F.

EndIf

//Posiciona Pedido quando Filial 40 (Três Coraçõess) para Validar Produtos x Operação 08-VENDA COM ICMS ST PAGO ANTERIORMENTE
SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )

SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))


If lProcOk .And. !(AllTrim(SZW->ZW_TIPO) $ '10/08') .And. AllTrim(SZW->ZW_FILIAL) = '40'

	If _lTela
		FWMsgRun( , {|| lProcOk := AOMS1123C( cNumPed , cFilAux,_lAutoref )}, "Aguarde!", "6-Validando Pedido Operacao 08 " + cNumPed	  )
	Else
		lProcOk := AOMS1123C( cNumPed , cFilAux,_lAutoref )
	EndIf

EndIf


//Posiciona pedido e cliente para mensagens

SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )

_cOper := SZW->ZW_TIPO

SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

lCliBloq:=If(SELECT("TRBF")<>0, (TRBF->BLOCLI == '1') , (SA1->A1_MSBLQL == '1'))
If lProcOk .And. lCliBloq

	If _lautoref
		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,cNumPed,SA1->A1_COD + "/"+SA1->A1_LOJA + " - "+AllTrim(SA1->A1_NOME),'Cliente/Remessa bloqueado'})
	Else
		U_ITMsg("Pedido ["+ AllTrim(cNumPed) +"] com Cliente/Remessa bloqueado: "+SA1->A1_COD + "/"+SA1->A1_LOJA + " - "+AllTrim(SA1->A1_NOME),"Validação Cliente/Remessa","verifique cadastro!",1)
	EndIf

	lProcOk := .F.

EndIf

If lProcOk .And. _cOper = "05" .And. Empty(AllTrim(SZW->ZW_CLIREM)) //Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
	If _lautoref
		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,cNumPed,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),'Pedido Triangular sem Código do cliente de Remessa'})
	Else
		U_ITMsg("Pedido ["+ AllTrim(cNumPed) +"] Falta código Cliente/Venda","Triangular","Informe o Código Cliente do Cliente/Venda!",1)
	EndIf

	lProcOk := .F.
EndIf

//Valida contra pedido com condições de pagamentos diversas entre os itens se não For bonificação
If lProcOk .And. _cOper != "10"

	If _lTela
		FWMsgRun( , {|| lProcOk := AOMS1128( cFilAux,cNumPed,_lautoref   )}, "Aguarde!", "7-Validando condições de pagamento do pedido " + cNumPed	  )
	Else
		lProcOk := AOMS1128( cFilAux,cNumPed,_lautoref   )
	EndIf
EndIf

//Locka registros
If lProcOk .And. !( AOMS112LO( cFilAux, cNumPed ,.F.) )
	If _lautoref
		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,cNumPed,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),'Pedido em uso por outra estação'})
	Else
		U_ITMsg("O Pedido ["+ AllTrim(cNumPed) +"] está sendo usado em outra estação!","Atenção",,1)
	EndIf

	Return
EndIf


If lProcOk .And. (Empty(cNumPed) .Or. Empty(cFilAux))

	If _lautoref
		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,cNumPed,'N/C','Falha ao identificar o pedido.'})
	Else
		U_ITMsg("Falha ao identificar o Pedido ["+ cNumPed +"]. Informar a área de TI/ERP","Atenção",,1)
	EndIf

	lProcOk := .F.

EndIf
//Posiciona pedido e cliente para mensagens
SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )

SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

//-- Verifica se deve executar as rotinas de Efetivação --//
If lProcOk .And. AOMS112VEF( cNumPed , cFilAux, _lAutoref ) //Retorna false se está tudo ok

	AOMS112UN(cFilAux,cNumPed)
	FWRestArea(aArea)
	Return

EndIf

//Posiciona pedido e cliente para mensagens
SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )

SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

//-- Validação de data entrega --//
If lProcOk

	If _lTela
		FWMsgRun(, {|| lProcOk := AOMS112ENT( _lAutoref ) }, "Aguarde!" , "8-Validando data de entrega do pedido " + cNumPed	 )
	Else
		lProcOk := AOMS112ENT( _lAutoref )
	EndIf

EndIf

//-- Validação da Tabela de Preços x Preços do Pedido --//
If lProcOk .And. AllTrim(SZW->ZW_TIPO) != '10'
	//Posiciona pedido e cliente para mensagens
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( cFilAux + cNumPed ) )

	SA1->(DBSetOrder(1))
	SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

	If _lTela
		FWMsgRun( , {|| lProcOk := AOMS112PRV( cNumPed , cFilAux,_lAutoref )}, "Aguarde!", "9-Validando Tabela de Preços do pedido " + cNumPed	  )
	Else
		lProcOk := AOMS112PRV( cNumPed , cFilAux,_lAutoref )
	EndIf

EndIf

//Posiciona pedido e cliente para mensagens
SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )

SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

//-- Chama a Rotina de Efetivação do Pedido se não existirem falhas de processamento --//
If lProcOk

	lProcOk:=AOMS112PEF( cNumPed , cFilAux, _lAutoref , _lTela )

EndIf

AOMS112UN(cFilAux,cNumPed)
FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa--------: AOMS1128
Autor-----------: Josué Danich Prestes
Data da Criacao-: 28/03/2018
Descrição-------: Valida pedido contra itens com condições de pagamento conflitantes
                  
Parametros------: _cCodFil - filial
				  				_cIdPedido - id do pedido
									_lAutoref - execução multipla de pedidos
Retorno---------: _lRet - validação do pedido
===============================================================================================================================
*/
Static Function AOMS1128(_cCodFil,_cIdPedido,_lAutoref)
	
Local _lRet := .T.
Local _ccond := ""
Local _ccondo := ""
Local _nni := 1
Local _aconf := {}
Local _ntotal  := 0
Local _nminimo := 0
Local _lValMinimo := .T.
Local _cFilSalva := cFilAnt
Default _lAutoref := .F.

Begin Sequence

	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( _cCodFil + _cIdPedido ) )

	_lValMinimo := (Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_I_VBROK") <> 'B' )

	While SZW->( !Eof() ) .And. _cCodFil + _cIdPedido == SZW->( ZW_FILIAL + ZW_IDPED )

		_ntotal += (SZW->ZW_QTDVEN * SZW->ZW_PRCVEN)

		_cCond := AOMS1125()

		_cproduto := AllTrim(SZW->ZW_PRODUTO) + " - " +  GetAdvFVal("SB1","B1_DESC",xFilial("SB1")+SZW->ZW_PRODUTO,1,"")

		aAdd(_aconf,{StrZero(Val(SZW->ZW_ITEM),3),"OK",_cCond,_cproduto})

		If _nni == 1

			_ccondo := _cCond

		ElseIf _ccondo != _cCond

			_aconf[Len(_aconf)][2] := "DIVERGÊNCIA"
			_lRet := .F.

		EndIf

		_nni++
		SZW->(DBSkip())
	EndDo

	If !_lRet

		If _lAutoref

			SZW->( DBSetOrder(1) )
			SZW->( DBSeek( _cCodFil + _cIdPedido ) )

			SA1->(DBSetOrder(1))
			SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

			aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),_cCodFil,_cIdPedido,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),'Existem divergências de condição de pagamento entre os produtos'})
		Else
			U_ITListBox( 'Existem divergências de condição de pagamento entre os produtos:' , {'Item','Situação','Condição','Produto'} , _aconf , .F. , 1 )
		EndIf

	EndIf

	//Valida para parcelas abaixo de R$ 300,00
	_aconf := {}
	If _lRet
		_cFilSalva := cFilAnt
		cFilAnt    := SZW->ZW_FILIAL
		_nminimo   := SuperGetMV("IT_SZWMIN",.T.,300)
		cFilAnt := _cFilSalva

		_apars := 	Condicao(_ntotal,_cCond,0,date())
		_cobs := ""

		For _nni := 1 to Len(_apars)

			_csitu := IIf(_lValMinimo .And. _apars[_nni][2] < _nminimo ,"DIVERGÊNCIA","OK")

			If _csitu == "DIVERGÊNCIA"

				_lRet := .F.
				_cobs += " - " + DToC(_apars[_nni][1]) + ": " + transform(_apars[_nni][2],"@E 999,999.99")

			EndIf

			aAdd(_aconf,{DToC(_apars[_nni][1]),transform(_apars[_nni][2],"@E 999,999.99"),_csitu})

		Next

		If !_lRet

			If _lAutoref

				SZW->( DBSetOrder(1) )
				SZW->( DBSeek( _cCodFil + _cIdPedido ) )

				SA1->(DBSetOrder(1))
				SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),_cCodFil,_cIdPedido,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),'Existem parcelas menores que o valor mínimo ( ' + transform(_nminimo,"@E 999,999.99")+ '):' + _cobs} )
			Else
				U_ITListBox( 'Existem parcelas menores que o valor mínimo ( ' + transform(_nminimo,"@E 999,999.99") + '):' , {'Data','Valor','Situação'} , _aconf , .F. , 1 )

			EndIf

		EndIf

	EndIf

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS112VEF
Autor-----------: Alexandre Villar
Data da Criacao-: 14/02/2014
Descrição-------: Verifica se o pedido está liberado para Efetivação e se não tem pedido gerado
Parametros------: cNumPed - Número do pedido de venda do portal
----------------: cFilAux - Filial do pedido de venda
									_lAutoref - execução multipla de pedidos
Retorno---------: lRet    - Informa se o pedido está bloqueado
===============================================================================================================================
*/
Static Function AOMS112VEF( cNumPed , cFilAux, _lAutoref )

Local aArea	:= FWGetArea()
Local lRet	:= .F.
Local _cMensBloq := ""

Default _lAutoref := .T.

DBSelectArea("SZW")
SZW->( DBSetOrder(1) )

If SZW->( DBSeek( cFilAux + cNumPed ) )

	SA1->(DBSetOrder(1))
	SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

	While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == cFilAux + cNumPed

		If !Empty(AllTrim(SZW->ZW_NUMPED))

			If _lAutoref

				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(SZW->ZW_NUMPED),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),'Já foi gerado pedido para esse registro!'})
			Else
				U_ITMsg( "Já foi gerado o pedido " + SZW->ZW_FILIAL + " - " + AllTrim(SZW->ZW_NUMPED) + " para esse registro!" , "Atenção!" ,,1 )
			EndIf

			lRet := .T.
			Exit

		EndIf

		If  (SZW->ZW_TIPO $ '10/24' .Or.  SZW->ZW_TPFRETE = "F" ) .And. SZW->ZW_BLOQ != "L" .And. !(lRet)

			Do Case
			Case SZW->ZW_TPFRETE = "F"
				_cMensBloq := "BLOQUEIO FRETE FOB"
			Case SZW->ZW_TIPO = '10'
				_cMensBloq := "BLOQUEIO DE BONIFICACAO"
			Case SZW->ZW_TIPO = '24'
				_cMensBloq := "BLOQUEIO DATA CRITICA"
			OtherWise
				_cMensBloq := "BLOQUEIO INEXISTENTE"
			EndCase

			RecLock("SZW",.F.)
			SZW->ZW_I_MOTBL := _cMensBloq
			SZW->ZW_DTAVAC := Date()
			SZW->ZW_HRAVAC := Time()
			SZW->(MSUnLock())

			If _lAutoref
				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME), AllTrim(_cMensBloq)})
			Else
				U_ITMsg( "Não é possível efetivar com" + _cMensBloq + " Pedido Nr " + AllTrim(cNumPed) , "Atenção" , ,1 )
			EndIf

			lRet := .T.

			Exit

		EndIf

		If SZW->ZW_BLQLCR == "B" .And. !(lRet) //Bloqueio de Crédito

			If _lAutoref

				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),'Pedido com bloqueio de crédito'})

			Else
				U_ITMsg( "Não é possível efetivar um Pedido Bloqueado Crédito.[" + AllTrim(cNumPed) + "]" , "Atenção!" , ,1 )
			EndIf

			lRet := .T.

			Exit

		EndIf

		If SZW->ZW_BLQLCR == "R" .And. !(lRet)  //Crédito Rejeitado

			If _lAutoref

				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),'Pedido com rejeição de crédito'})
			Else
				U_ITMsg( "Não é possível efetivar um Pedido Rejeitado Crédito.[" + AllTrim(cNumPed) + "]" , "Atenção!" , ,1 )
			EndIf

			lRet := .T.
			Exit

		EndIf


		If (SZW->ZW_BLOPRC == 'B' .Or. SZW->ZW_BLOPRC == 'R') .And. !(lRet)

			If _lAutoref

				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),'Pedido com bloqueio ou recusa de preço'})
			Else
				U_ITMsg( "Não é possível efetivar um Pedido com Preço Bloqueado ou Recusado.[" + AllTrim(cNumPed) + "]" , "Atenção!" , ,1 )
			EndIf

			lRet := .T.
			Exit

		EndIf


		SZW->( DBSkip() )
	EndDo

EndIf

FWRestArea(aArea)

Return( lRet )

/*
===============================================================================================================================
Programa--------: AOMS112LCR
Autor-----------: Alexandre Villar
Data da Criacao-: 14/02/2014
Descrição-------: Valida Limite de Crédito do Cliente para Efetivação do Pedido de Venda.
Parametros------: cNumPed - Número do pedido de venda do portal
----------------: cFilAux - Filial do pedido de venda
									_lAutoref - execução de múltiplos pedidos
Retorno---------: lRet    - Informa o resultado da validação
===============================================================================================================================
*/
Static Function AOMS112LCR( cNumPed , cFilAux, _lAutoref )

Local aAreaAux	:= FWGetArea()
Local lOk		:= .T.
Local cCodCli	:= ""
Local cLojCli	:= ""
Local lbq := .F.

Local _nTotped   := 0
Local _aRetCre   := _cRetDes := _cRetSta := _cRetTip := _cRetDesC:= ""
Local _cGerente, _cCoordena, _cSupervis, _cRepresen
Local _cRetMsg, _aOrd, _nRegSA3
Default _lAutoref := .F.

If Empty(cNumPed) .Or. Empty(cFilAux)

	If _lAutoref
		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,cNumPed,"N/C",'Falha ao identificar o pedido'})
	Else
		U_ITMsg( "Falha ao identificar o Pedido.","Atenção","Informar a área de TI/ERP:[AOMS112003]" ,  1 )
	EndIf
	lOk := .F.

Else

	//-- Posiciona na Tabela de Pedidos do Portal --//
	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	If SZW->( DBSeek( cFilAux + cNumPed ) ) .And. lOk

		//-- Recupera Código/Loja do Cliente --//
		cCodCli := SZW->ZW_CLIENTE
		cLojCli	:= SZW->ZW_LOJACLI

		_cGerente  := " "
		_cCoordena := " "
		_cSupervis := " "
		_cRepresen := " "
		_aOrd      :=  SaveOrd({"SA3"})
		_nRegSA3   := SA3->(Recno())

		SA3->(DBSetOrder(1))

		If !Empty(SZW->ZW_VEND1)

			_cRepresen := SZW->ZW_VEND1

			If ! SA3->(DBSeek(xFilial("SA3")+_cRepresen))

				If _lAutoref
					SA1->(DBSetOrder(1))
					SA1->(DBSeek(xFilial("SA1")+cCodCli+cLojCli))
					aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),"O código de representante " + _cRepresen + " não está cadastrado no cadastro de Vendedores."})
				Else
					U_ITMsg("O código de representante não está cadastrado no cadastro de Vendedores.","Atenção!" ,_cRepresen ,1 )
				EndIf

				lOk := .F. //Retorna .F. para controle de processamento da rotina
				lBq := .T. //Seta .T. na variável de Controle de Bloqueio de Pedidos

			EndIf

		Else

			If _lAutoref

				SA1->(DBSetOrder(1))
				SA1->(DBSeek(xFilial("SA1")+cCodcli+cLojCli))

				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),"O código de representante não está preenchido"})
			Else
				U_ITMsg("O código de representante não está preenchido.","Atenção!" , ,1 )
			EndIf

			lOk := .F. //Retorna .F. para controle de processamento da rotina
			lBq := .T. //Seta .T. na variável de Controle de Bloqueio de Pedidos

		EndIf

		If lOk

			If !Empty(SA3->A3_SUPER) // SZW->ZW_VEND2
				_cCoordena := SA3->A3_SUPER
			EndIf

			If !Empty(SA3->A3_GEREN) // SZW->ZW_VEND3
				_cGerente  := SA3->A3_GEREN
			EndIf

			If !Empty(SA3->A3_I_SUPE) // SZW->ZW_VEND4
				_cSupervis := SA3->A3_I_SUPE

			EndIf

		EndIf

		RestOrd(_aOrd)
		SA3->(DBGoTo(_nRegSA3))

		If lOk

			//-- Posiciona no Cliente Atual (Cód.+Loja) para recuperar o Código do Risco e a Validade do Limite de Crédito --//
			DBSelectArea("SA1")
			SA1->( DBSetOrder(1) )

			If SA1->( DBSeek( xFilial("SA1") + cCodCli + cLojCli ) )

				If AllTrim(SZW->ZW_TIPO) != '10' //Não valida para bonificação

					_nTotped := U_AOMS112Y( cCodCli , cLojCli , cNumPed )

					_aRetCre := U_ValidaCredito( _nTotped , cCodCli , cLojCli , .T., {|| SZW->ZW_BLQLCR == "C" }, SZW->ZW_LIBL, _nTotped, 1,," ", _cGerente, _cCoordena, _cSupervis, _cRepresen, SZW->ZW_CONDPAG)

					_cRetDes := _aRetCre[1]// Descricoes da avaliaçãode credito
					_cRetSta := _aRetCre[2]// "B" , "L"
					_cRetTip := _aRetCre[3]// 1=Limite Expirado ; 2=Atraso Titulos ; 3=Limite Excedido ; 4=Risco ; 5=Automatico

					If Len(_aRetCre) > 3
						_cRetDesC:= " - "+_aRetCre[4]// Complemento da descricoes da avaliação de credito
					Else
						_cRetDesC:= ""
					EndIf

					lOk := .T.

					If _cRetSta = "B"

						If U_AOM112GA( cNumPed , cFilAux , _cRetSta , _cRetTip , _cRetDes+_cRetDesC,,_nTotped ) // 1=Limite Expirado;2=Atraso Titulos;3=Limite Excedido;4=Risco;5=Automatico
							_cRetMsg := Upper(_cRetDes)

							If "INATIVO" $ _cRetMsg
								If _lAutoref
									aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),_cRetDes})
								Else
									U_ITMsg(_cRetDes + CRLF + CRLF + _cRetDesC,"Atenção!" , ,1 )
								EndIf
							Else
								If _lAutoref
									aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),"O pedido atual será " + _cRetDes})
								Else
									U_ITMsg("O pedido atual será " + _cRetDes + CRLF + CRLF + _cRetDesC,"Atenção!" , ,1 )
								EndIf
							EndIf

							lOk := .F. //Retorna .F. para controle de processamento da rotina
							lBq := .T. //Seta .T. na variável de Controle de Bloqueio de Pedidos

						EndIf

					EndIf

				EndIf

			EndIf


		ElseIf !SA1->( DBSeek( xFilial("SA1") + cCodCli + cLojCli ) )

			If _lAutoref
				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),cCodcli+"/"+cLojCli,"Falha ao posicionar no Cliente/Remessa para validação do Limite de Crédito."})
			Else
				U_ITMsg( "Falha ao posicionar no Cliente/Remessa para validação do Limite de Crédito.", "Atenção! ","Informar a área de TI/ERP"  , 1 )
			EndIf

			lOk := .F. //Retorna .F. para controle de processamento da rotina

		EndIf//If SA1->( DBSeek( xFilial("SA1") + cCodCli + cLojCli ) )

	Else//If SZW->( DBSeek( cFilAux + cNumPed ) ) .And. lok

		If _lAutoref
			aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),"N/C","Falha ao posicionar no Pedido para validação do Limite de Crédito.."})
		Else
			U_ITMsg( "Falha ao posicionar no Pedido para validação do Limite de Crédito.", "Atenção!","Informar a área de TI/ERP"   ,1 )
		EndIf
		lOk := .F. //Retorna .F. para controle de processamento da rotina

	EndIf//If SZW->( DBSeek( cFilAux + cNumPed ) ) .And. lok

EndIf

FWRestArea(aAreaAux)

If lBq //Atualiza o bloqueio de crédito do browse posicionado

	If Select("TRBF") <> 0
		TRBF->( RecLock( "TRBF", .F. ) )
		TRBF->BLQLCR := "B"
		TRBF->( MSUnLock() )
	EndIf

EndIf

Return( lOk )

/*
===============================================================================================================================
Programa--------: AOMS112PRV
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Valida Preço de Venda dos Itens do Pedido do Portal
Parametros------: cNumPed   := Código do Pedido
----------------: cFilAux   := Filial do Pedido
				  _lAutoref := Execução de pedidos múltiplos
Retorno---------: lRet := Informa se validou os preços do pedido
===============================================================================================================================
*/
Static Function AOMS112PRV( cNumPed , cFilAux, _lAutoref )

Local aAreaAux	:= FWGetArea()
Local lOk		:= .T.
Local _lRet  	:= .T.
Local lbq       := .F.
Local _nPesoBrutoPedido := 0
Local _nPesoParam := SuperGetMV("IT_PESOFEC",.T.,4000)
Local _cTpVenda := ""
Local _nPrecoTabela := 0
Local _lBlqPrc  := .F.
Local _cCoord   := ""
Local _cWF      := ""
Local _lSimplNac :=  .F.
Local _aBlqprc := {}

_cFilSalva  := cFilAnt
cFilAnt     := SZW->ZW_FILIAL
cFilAnt     := _cFilSalva

_cTpVenda := SZW->ZW_TPVENDA

_nPesoBrutoPedido := AOMS112PES(cFilAux,cNumPed)

If Empty(AllTrim(_cTpVenda))
	_cTpVenda := "F" //Carga Fechada
	If _nPesoBrutoPedido <= _nPesoParam
		_cTpVenda := "V" //Carga Fracionada (Varejo)
	EndIf
EndIf

If _cTpVenda = "F" .And. _nPesoBrutoPedido <= _nPesoParam //Quando Carga Fechada o Peso do Pedido tem que ser maior que o Parâmetro definido
	If _lAutoref
		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SZW->ZW_CLIENTE + " " + SZW->ZW_LOJACLI,"Tipo de Vendas Carga Fechada, nao Permitido para Pedido com Peso Menor que " + AllTrim(Transform(_nPesoParam,"@E 99,999.99")) ,"Verifique o Pedido com Peso igual " + AllTrim(Transform(_nPesoBrutoPedido,"@E 99,999.99")) })
	Else
		U_ITMsg("Tipo de Vendas Carga Fechada, nao Permitido para Pedido com Peso Menor que " + AllTrim(Transform(_nPesoParam,"@E 99,999.99")) ,"Atenção","Verifique o Pedido com Peso igual " + AllTrim(Transform(_nPesoBrutoPedido,"@E 99,999.99")) ,1)
	EndIf
	_lRet := .F.
	lok := .F.
EndIf

SZW->(DBSetOrder(1))
If SZW->(DBSeek(cFilAux + cNumPed))

	If ( SZW->ZW_BLOPRC == "B" .Or. Empty(AllTrim(SZW->ZW_BLOPRC))) .And. _lRet

		_cvend2 := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")
		_cvend3 := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_GEREN")

		If SZW->ZW_FILPRO != '0 ' .And. !Empty(SZW->ZW_FILPRO) .And. SZW->ZW_FILPRO != SZW->ZW_FILIAL

			_cfilpro := SZW->ZW_FILPRO

		Else

			_cfilpro := SZW->ZW_FILIAL

		EndIf

		_cTab	:= SZW->ZW_TABELA

		//Valida tabela de preços selecionada
		DA0->(DBSetOrder(1))
		If !(DA0->(DBSeek(xFilial("DA0")+_ctab)))
			If _lAutoref
				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SZW->ZW_CLIENTE + " " + SZW->ZW_LOJACLI,"Tabela de preços " + _cTab + " não localizada!"})
			Else
				U_ITMsg("Tabela de preços " + _cTab + " não localizada!","Atenção","Verifique regras de tabelas de preço",1)
			EndIf
			_lRet := .F.
			lok := .F.
		Else //Encontrou Tabela de Preço DA0010


			SA1->(DBSetOrder(1))
			SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

			_lSimplNac  :=If(SA1->A1_SIMPNAC="1",.T.,.F.)

			While SZW->ZW_FILIAL == cFilAux .And. SZW->ZW_IDPED == cNumPed
				DA1->(DBSetOrder(1))
				If DA1->(DBSeek(xFilial("DA1")+SZW->ZW_TABELA+SZW->ZW_PRODUTO))
					If SZW->ZW_TPVENDA == "F"
						_nPrecoTabela := DA1->DA1_PRCVEN
					Else
						_nPrecoTabela := DA1->DA1_I_PRFE
					EndIf

					If SZW->ZW_PRUNIT < _nPrecoTabela .And. SZW->ZW_PRCVEN < _nPrecoTabela .And. SZW->ZW_KIT == ' ' 

						_aBlqprc := U_BLQPRC(SZW->ZW_PRODUTO,SZW->ZW_PRCVEN,       cFilAux,   .F.,         _cTab,    .T.,      .T.,        .T.,           ,         ,SA1->A1_EST,,     _cTpVenda,_lSimplNac,_nPesoBrutoPedido,SZW->ZW_I_FXPES)

						_lbloq   := _aBlqprc[1]
						If (_lbloq)
							_lRet := .F.
							_lBlqPrc  := .T.

							RecLock("SZW",.F.)
							SZW->ZW_PRUNIT := _nPrecoTabela
							SZW->(MSUnLock())

						EndIf
					EndIf

				Else
					If _lAutoref
						aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SZW->ZW_CLIENTE + " " + SZW->ZW_LOJACLI,"Item não Localizado na Tabela de preços " + _cTab + " não localizada!"})
					Else
						U_ITMsg(" Item: " + SZW->ZW_PRODUTO + " Tabela: " + _cTab + " não localizada!","Atenção","Verifique regras de tabelas de preço",1)
					EndIf
					_lRet := .F.
					lok  := .F.
				EndIf
				SZW->(DBSkip())

			EndDo

		EndIf
		If _lBlqPrc

			DBSelectArea("SZW")
			SZW->( DBSetOrder(1) )

			If SZW->( DBSeek( cFilAux + cNumPed ) )
				_cCoord:= Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")
				_cWF   := Posicione("SA3",1,xFilial("SA3")+_cCoord,"A3_I_WF")
				While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == cFilAux + cNumPed

					RecLock("SZW",.F.)
					If _cWF == "2"
						SZW->ZW_BLOPRC  := ' '
						SZW->ZW_STATUS  := 'L'
						SZW->ZW_ENVWF   := 'C'
						SZW->ZW_NIVELWF := 'P'
						SZW->ZW_I_HTML  := ' '
						SZW->ZW_OBSAVAC := ' '
						SZW->ZW_DATAAPR := ' '
						SZW->ZW_BLQLCR  := ' '
						SZW->ZW_I_OBS   := ' '
						SZW->ZW_MOTLP   := ' '
					Else
						SZW->ZW_BLOPRC  := ' '
						SZW->ZW_STATUS  := 'A'
						SZW->ZW_ENVWF   := ' '
						SZW->ZW_NIVELWF := ' '
						SZW->ZW_I_HTML  := ' '
						SZW->ZW_OBSAVAC := ' '
						SZW->ZW_DATAAPR := ' '
						SZW->ZW_BLQLCR  := ' '
						SZW->ZW_I_OBS   := ' '
						SZW->ZW_MOTLP   := ' '
					EndIf
					SZW->(MSUnLock())
					SZW->(DBSkip())
				EndDo

			EndIf
		EndIf
		//Desfaz lock nos registros
		AOMS112UN(cFilAux,cNumPed)

		If !_lRet

			If _lAutoref //Qdo marca vários

				SZW->( DBSetOrder(1) )
				SZW->( DBSeek( cFilAux + cNumPed ) )

				SA1->(DBSetOrder(1))
				SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

				aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),"Existe(m) item(ns) cujo(s) preço(s) informado(s) está(ão) fora da tabela de preços praticada pela empresa."})
			Else
				U_ITMsg("Existe(m) item(ns) cujo(s) preço(s) informado(s) está(ão) fora da tabela de preços praticada pela empresa. ","Validação de preços",;
					"O pedido será marcado como bloqueado para posterior avaliação.", 1	)
			EndIf

			lok := .F.
			lBq := .T. //Seta .T. na variável de Controle de Bloqueio de Pedidos

		EndIf

	EndIf

Else

	If _lAutoref

		SZW->( DBSetOrder(1) )
		SZW->( DBSeek( cFilAux + cNumPed ) )

		SA1->(DBSetOrder(1))
		SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD + "/"+SA1->A1_LOJA + " - "+AllTrim(SA1->A1_NOME),"Existe(m) item(ns) cujo(s) preço(s) informado(s) está(ão) fora da tabela de preços praticada pela empresa."})
	Else

		U_ITMsg( "Falha ao posicionar no Pedido para validação de Preços.", "Atenção!","Informar a área de TI/ERP" , 1 )

	EndIf
	lOk := .F. //Retorna .F. para controle de processamento da rotina
EndIf

FWRestArea(aAreaAux)

Return( lOk )

/*
===============================================================================================================================
Programa--------: AOMS112PEF
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Validações pré-efetivação dos pedidos de vendas do portal
Parametros------: cNumPed - Número do pedido de venda do portal
----------------: cFilAux - Filial do pedido de venda
									_lAutoref - Execução de múltiplas efetivações
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112PEF( CPED , cFlVer, _lAutoref , _lTela)

Local cTitulo	:= "Efetivação de Pedidos Portal"
Local lRetMod2  := .F. // Retorno da função Modelo2 - .T. Confirmou / .F. Cancelou
Local lBLQLCR	:= .F. // Variavel que identifica bloqueio por Limite de Credito [Chamado: 5413]
Local nLinha	:= 0
Local _lRet 	:= .T.
Local _nRegAtu, _aOrd  , nColuna
Local lbq := .F.

Default _lAutoref := .F.

Private _nPosLocal, _nPosProd, _nPosItem

Public nOpcx	:= 6

nUsado	:= 0
aHeader	:= {}
aCols	:= {}
cDescr	:= ""
nQtd2UM	:= 0
c2UM	:= ""
nVlrTot	:= 0
nVTot	:= 0

// Montagem do aHeader
aHeader := {	{ "Item"		  	, "ZW_ITEM"		, "@!"					, 010 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Produto"	  		, "ZW_PRODUTO"	, "@!"					, 015 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Descrição"	  	, "cDescr" 		, "@!"					, 020 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Qtd Ven 2 UM"  	, "nQtd2UM"		, "@e 999,999,999.99"	, 014 , 2 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Segunda UM"	   	, "c2UM"		, "@!"					, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Quantidade"		, "ZW_QTDVEN"	, "@e 999,999,999.99"	, 014 , 2 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Unidade"		   	, "ZW_UM"		, "@!"					, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Prc Unitario" 	, "ZW_PRCVEN"	, "@e 9,999,999.9999"	, 014 , 4 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Vlr.Total "		, "nVlrTot"		, "@e 999,999,999.99"	, 014 , 2 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Blq. Preço "		, "ZW_BLOPRC"	, "@!"					, 001 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" },;
	{ "Local "		    , "ZW_LOCAL"	, "@!"					, 002 , 0 , "AllwaysTrue()" , "" , "C" , "" , "R" } }

_nPosLocal := aScan(aHeader,{|x| x[2] = "ZW_LOCAL"})
_nPosProd  := aScan(aHeader,{|x| x[2] = "ZW_PRODUTO"})
_nPosItem  := aScan(aHeader,{|x| x[2] = "ZW_ITEM"})

_aButtons := {}
aAdd(_aButtons,{"Alt.Armazem",{|| U_AOMS112B(N,_nPosLocal,_nPosProd) },"Altera Armazem","Altera Armazem"})

DBSelectArea("SZW")
SZW->( DBSetOrder(1) )
If SZW->( DBSeek( cFlVer + CPED ) )

	// Montagem do aCols
	While SZW->( !Eof() ) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == cFlVer + CPED

		aAdd( aCols , Array( Len(aHeader) + 1 ) )
		nLinha++

		cDescr		:= GetAdvFVal( "SB1" , "B1_I_DESCD"	, xFilial("SB1") + AllTrim( SZW->ZW_PRODUTO )	, 1 , "" )
		nFatConv	:= GetAdvFVal( "SB1" , "B1_CONV"	, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )
		cTpConv		:= GetAdvFVal( "SB1" , "B1_TIPCONV"	, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )
		nNewFat		:= GetAdvFVal( "SB1" , "B1_I_FATCO"	, xFilial("SB1") + SZW->ZW_PRODUTO				, 1 , "" )

		If cTpConv == "M"
			nQtd2UM	:= IIf( nFatConv == 0 , nNewFat * SZW->ZW_QTDVEN , nFatConv * SZW->ZW_QTDVEN )
		Else
			nQtd2UM	:= IIf( nFatConv == 0 , SZW->ZW_QTDVEN / nNewFat , SZW->ZW_QTDVEN / nFatConv )
		EndIf

		c2UM		:= GetAdvFVal( "SB1" , "B1_SEGUM" , xFilial("SB1") + AllTrim( SZW->ZW_PRODUTO ) , 1 , "" )
		nVlrTot		:= SZW->ZW_QTDVEN * SZW->ZW_PRCVEN
		nVtot		+= nVlrTot

		For nColuna := 1 to Len(aHeader)
			aCols[nLinha][nColuna] := &( aHeader[nColuna][2] )
		Next nColuna

		aCols[nLinha][Len(aHeader)+1] := .F. // Linha não deletada

		SZW->( DBSkip() )
	EndDo

	cFli		:= Space(20)
	cFilPro		:= Space(040)
	cTipPed		:= Space(15)
	cNumPed		:= Space(25)
	cVincula    := Space(1)
	cCliente	:= Space(06)
	cNomCli		:= Space(60)
	cLojaCli	:= Space(04)
	cGrpCli		:= Space(30)
	cCond		:= Space(50)
	cVend1		:= Space(06)
	cNmVend1	:= Space(40)
	cVend2		:= Space(06)
	cNmVend2	:= Space(40)
	cPedCli		:= Space(09)
	dDtEnt		:= CtoD("")
	cTipoAg     := Space(10)
	cHrEnt		:= Space(05)
	cSha		:= Space(14)
	cTipFre	:= Space(10)
	cTipCar	:= Space(15)
	cQtdCha	:= Space(03)
	cHrDes		:= Space(05)
	nCusDes	:= 0
	cObsCom	:= Space(300)
	cObsNF	:= Space(300)

	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( SubStr( cFlVer , 1 , 2 ) + CPED ) )

	csuper := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_I_SUPE")
	_ccoord  := SA3->A3_SUPER
	_cgeren := SA3->A3_GEREN

	ctabela := SZW->ZW_TABELA + " - " + Posicione("DA0",1,xFilial("DA0")+SZW->ZW_TABELA,"DA0_DESCRI")

	SZW->( DBSeek( SubStr( cFlVer , 1 , 2 ) + CPED ) )

	dDtEnt		:= SZW->ZW_FECENT
	_laltera := .T.

	If SZW->ZW_I_AGEND == 'P'

		//cTipoAg		:= SZW->ZW_I_AGEND+" - AGUARD AGENDA"

		If month(date()) != 12

			dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+1)))+"0101")-1

		Else

			dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+2)))+"0101")-1

		EndIf

		_laltera := .F.

	EndIf

	If SZW->ZW_I_AGEND $ 'I/O'//I=Imediata //O=Agendada pelo Op.Log.
		_cFilCarreg := SZW->ZW_FILIAL
		If !Empty(SZW->ZW_FILPRO) .And. !(AllTrim(SZW->ZW_FILPRO)=='0')
			_cFilCarreg := SZW->ZW_FILPRO
		EndIf

		//cTipoAg		:= SZW->ZW_I_AGEND+" - IMEDIATO"
		dDtEnt 		:=  SZW->ZW_FECENT
		_laltera := .F.
	EndIf
	cTipoAg:=SZW->ZW_I_AGEND+" - "+(U_TipoEntrega(SZW->ZW_I_AGEND))

If !_lAutoref //Se é execução múltipla não apresenta tela de modelo2

	// aC[n,1] = Nome da Variavel Ex.:"cCliente"
	// aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aC[n,3] = Titulo do Campo
	// aC[n,4] = Picture
	// aC[n,5] = Validacao
	// aC[n,6] = F3
	// aC[n,7] = Se campo e' editavel .T. se nao .F.
	_cVal3:=" U_AOM112Val('cTipPed',LEFT(cFilPro,2),LEFT(cFli,2)) "
	aC := {	{ "cFli"	,{015,003} 	,"Filial                   "   		,"@!"   				,	, "SM0" ,.F. 	},;
		{ "cFilPro" 	,{015,203} 	,"Filial Carregamento   "        	,"@!"   				,   , "SM0" ,.F.	},;
		{ "cVincula" 	,{030,423} 	,"Vincula Pedido? "              	,"@!"   				,   ,       ,.T.	},;
		{ "cTipPed"		,{030,003} 	,"Tipo Pedido       " 	  			,"@!"   				,_cVal3,"ZB4",.F. 	},;//editavel se TRBF->TIPO == '01' .Or. TRBF->TIPO == '03'
		{ "cNumPed"		,{030,203} 	,"Num. Pedido " 	  				,"@!"   				,	,		,.F.	},;
		{ "cCliente"	,{045,003} 	,"Cliente/Remessa" 	 				,"@!"   				,	,		,.F.	},;
		{ "cLojaCli"	,{045,085} 	,"Loja   "							,"@!"   				,	,		,.F.	},;
		{ "cNomCli"		,{045,140} 	,"Nome Cliente/Remessa"				,"@!"   				,	,		,.F.	},;
		{ "cGrpCli"		,{060,003} 	,"Grupo Cliente/Rem."				,"@!"   				,	,		,.F.	},;
		{ "cCond"		,{060,285} 	,"Cond. Pagto" 						,"@!"   				,	,		,.F.	},;
		{ "cVend1"		,{075,003} 	,"Vendedor 1       "  				,"@!"   				,	,		,.F.	},;
		{ "cNmVend1"	,{075,140} 	,"Nome Vendedor 1" 					,"@!"   				,	,		,.F.	},;
		{ "nVTot"		,{075,500} 	,"Valor Total   " 					,"@e 999,999,999.99"	,	,		,.F.	},;
		{ "cVend2"		,{090,003} 	,"Vendedor 2       "  				,"@!"   				,	,		,.F.	},;
		{ "cNmVend2"	,{090,140} 	,"Nome Vendedor 2" 					,"@!"   				,	,		,.F.	},;
		{ "cPedCli"		,{105,003} 	,"Pedido Cliente/Remessa    "		,"@!"   				,	,		,.F.	},;
		{ "dDtEnt"		,{015,500} 	,"Data Entrega          "			,"@!"   				,	,		,_laltera 	},;//editavel
		{ "cTipoAg"		,{030,500}	,"Tipo Agendamento"					,"@!"   				,	,		,.F.	},;
		{ "cHrEnt"		,{105,245} 	,"Hora Entrega   "					,"@E 99:99 "   			,	,		,.T. 	},;//editavel
		{ "cSha"		,{105,325} 	,"Senha                "			,"@!"   				,	,		,.F.	},;
		{ "cTipFre"		,{105,500} 	,"Tipo Frete    "					,"@!"   				,	,		,.F.	},;
		{ "cTipCar"		,{120,003} 	,"Tipo de Carga      "				,"@!"   				,	,		,.F.	},;
		{ "cQtdCha"		,{120,140} 	,"Qtd. Chapa           "			,"@!"   				,	,		,.F.	},;
		{ "cHrDes"		,{120,245} 	,"Hora Descarga"					,"@!"   				,	,		,.F.	},;
		{ "nCusDes"		,{120,325} 	,"Custo Descarga"					,"@e 999,999,999.99"	,	,		,.F.	},;
		{ "ctabela"		,{120,430} 	,"Tabela Preço"						,"@!"					,	,		,.F.	},;
		{ "cObsCom"		,{135,003} 	,"Obs. Comercial  "					,"@!"					,	,		,.F.	},;
		{ "cObsNf"		,{150,003} 	,"Mensagem NF    "					,"@!"					,	,		,.F.	} }

	aAdd(aC,{"cVECliente",{165,003},"Cliente / Venda" 	 	    ,"@!",,,.F.})
	aAdd(aC,{"cVELojaCli",{165,085},"Loja   "					,"@!",,,.F.})
	aAdd(aC,{"cRENomCli" ,{165,140},"Nome Cliente/Venda        ","@!",,,.F.})

	// Tratamento da Operação Triangular
	// Array com descricao dos campos do Rodape do Modelo 2
	// aR[n,1] = Nome da Variavel Ex.:"cCliente"
	// aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aR[n,3] = Titulo do Campo
	// aR[n,4] = Picture
	// aR[n,5] = Validacao
	// aR[n,6] = F3
	// aR[n,7] = Se campo e' editavel .T. se nao .F.
	//Define se pode editar tipo do pedido
	If SZW->ZW_TIPO == '01' .Or. SZW->ZW_TIPO == '03'
		aC[3,7] := .T.
	EndIf
EndIf

	aR := {}

	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( cFlVer + CPED ) )

	cFli		:= Left(SubStr(cFlVer,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(cFlVer,1,2),1,""),25)
	cFilPro		:= If(!Empty(SZW->ZW_FILPRO), SubStr( SZW->ZW_FILPRO , 1 , 2 ) +" - "+ GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(SZW->ZW_FILPRO,1,2),1,"")  , Space(Len(cFli)) )
	cTipPed		:= SubStr(SZW->ZW_TIPO+" - "+GetAdvFVal("ZB4","ZB4_DESCRI",xFilial("ZB4")+SZW->ZW_TIPO,1,""),1,25)


	cNumPed  	:= CPED
	cCliente 	:= SZW->ZW_CLIENTE
	cLojaCli 	:= SZW->ZW_LOJACLI
	cVincula    := "N"
	cNomCli 	:= GetAdvFVal("SA1","A1_NOME",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")
	cGrpCli		:= GetAdvFVal("SA1","A1_GRPVEN",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")+" - "+GetAdvFVal("SA1","A1_I_NGRPC",xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI,1,"")
	cCond		:= AOMS1125()
	cVend1	 	:= SZW->ZW_VEND1
	cNmVend1 	:= GetAdvFVal("SA3","A3_NOME",xFilial("SA3")+SZW->ZW_VEND1,1,"")
	cVend2   	:= SZW->ZW_VEND2
	cNmVend2 	:= GetAdvFVal("SA3","A3_NOME",xFilial("SA3")+SZW->ZW_VEND2,1,"")
	nVTot 		:= nVTot
	cPedCli		:= SZW->ZW_PEDCLI

	cHrEnt		:= SZW->ZW_HOREN
	cSha		:= SZW->ZW_SENHA
	cTipFre	  	:= If(SZW->ZW_TPFRETE == 'C',SZW->ZW_TPFRETE+" - CIF",SZW->ZW_TPFRETE+" - FOB")
	_cchep 		:= Posicione("SA1",1,xFilial("SA1")+ccliente+cLojaCli,"A1_I_CCHEP")
	cTipCar		:= If( !Empty(_cchep) , "1 - Paletizada" , "2 - Batida" )
	cQtdCha	  	:= SZW->ZW_CHAPA
	cHrDes		:= SZW->ZW_HORDES
	nCusDes	  	:= SZW->ZW_CUSDES
	cObsCom	  	:= SZW->ZW_OBSCOM
	cObsNF		:= SZW->ZW_MENNOTA
	cVECliente 	:= SZW->ZW_CLIREM
	cVELojaCli 	:= SZW->ZW_LOJEN

	cRENomCli	:= IIf(Empty(SZW->ZW_CLIREM),"  ",Posicione("SA1",1,xFilial("SA1")+SZW->ZW_CLIREM+SZW->ZW_LOJEN,"A1_NOME"))

	aCGD		:= { 350 , 06 , 26 , 74 } // Array com coordenadas da GetDados no modelo2

	// Verificação de bloqueio de crédito e bonificação
	_aItensLock:={}
	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( cFlVer + cNumPed ) )
	While SZW->( !Eof() ) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == cFlVer + cNumPed

		If SZW->ZW_TIPO == "05"
			SZW->(RecLock("SZW",.F.))
			SZW->ZW_TIPO:=cTipPed:=cTp:="42"
			SZW->(MSUnLock())
		EndIf

		If SZW->ZW_BLQLCR == "B"
			lBLQLCR := .T.
			Exit
		EndIf

		SZW->( DBSkip() )
	EndDo
	_lRet:=!lBLQLCR
	// Realiza o processamento de Preço somente se ja estiver liberado no Credito
	If !lBLQLCR

		If _lAutoref //Se é execução múltipla não apresenta tela de modelo2

			_lRet:=lRetMod2 := .T.

		Else
			//( cTitulo , aC , aR , aGd  , nOp   ,cLinhaOk,cTudoOk ,aGetsD,bF4,cIniCpos,nMax,aCordW,lDelGetD,lMaximazed ] [ aButtons ] )
			_lRet:=lRetMod2 := Modelo2( cTitulo , aC , aR , aCGD , nOpcx ,        ,        , aR   ,   ,        ,9999,      ,        , .T. ,_aButtons)

		EndIf

		If lRetMod2
			// GRAVAÇÃO DOS DADOS DO ARMAZEM
			_nRegAtu := SZW->(Recno())
			_aOrd    := SaveOrd({"SZW"})
			SZW->( DBSetOrder(1) ) // ZW_FILIAL+ZW_IDPED
			If SZW->( DBSeek( cFlVer + CPED ) )
				While !SZW->(Eof()) .And. SZW->(ZW_FILIAL+ZW_IDPED) == cFlVer + CPED
					_nI := aScan(aCols,{|x| x[_nPosItem] == SZW->ZW_ITEM})  // _nPosLocal // ZW_ITEM
					If _nI > 0
						SZW->(RecLock("SZW",.F.))
						SZW->ZW_LOCAL := aCols[_nI,_nPosLocal]
						SZW->(MSUnLock())
					EndIf

					SZW->(DBSkip())
				EndDo
			EndIf
			RestOrd(_aOrd)
			SZW->(DBGoTo(_nRegAtu))

			If lBq // Registra o Bloqueio por Preço para todos os itens do Pedido
				_lRet:=.F.
				If !lBLQLCR .And. SZW->ZW_BLOPRC == "B" .Or. Empty( AllTrim( SZW->ZW_BLOPRC ) )

					DBSelectArea("SZW")
					SZW->( DBSetOrder(1) )
					SZW->( DBSeek(cFlVer+cNumPed) )
					While SZW->(!Eof()) .And. cFlVer + cNumPed == SZW->( ZW_FILIAL + ZW_IDPED )

						RecLock( "SZW" , .F. )
						SZW->ZW_BLOPRC := "B"
						SZW->ZW_STATUS := "P"
						SZW->( MSUnLock() )

						SZW->( DBSkip() )
					EndDo
					If Select("TRBF") <> 0
						TRBF->( RecLock( "TRBF", .F. ) )
						TRBF->BLOPRC := 'B'
						TRBF->( MSUnLock() )
					EndIf

				EndIf

			Else

				//Valida se campo vincula pedido está corretamente preenchido
				If _lAutoref .And. !( cVincula $ ("SN") )

					cVincula := "S"

				Else

					If !( cVincula $ ("SN") )

						If U_ITMsg("Pedido deve ficar disponível para vinculação?","Atenção","Clicando em Sim o pedido não será enviado para o RDC até ser vinculado",2,2,2)

							cVincula := "S"

						Else

							cVincula := "N"


						EndIf


					EndIf

				EndIf
				If _lTela
					FWMsgRun(, {|_oSay| _lRet:=AOMS112GC5( cFlVer , _oSay, _lAutoref , _lTela ) }, 'Aguarde!' , 'Efetivando o Pedido: '+cFlVer+" "+cNumPed , .F. )//-- Chama a Rotina de Geração de Pedidos de Venda --//
				Else
					_lRet:=AOMS112GC5( cFlVer , , _lAutoref  , _lTela )
				EndIf

			EndIf

		EndIf

	EndIf

Else

	U_ITMsg( 'Não foi possível posicionar no pedido!' ,'Atenção!',,1 )
	_lRet:=.F.
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS112Y
Autor-----------: Alexandre Villar
Data da Criacao-: 14/02/2014
Descrição-------: Valida o saldo disponível no Limite de Crédito do Cliente para verificar se o pedido atual excede.
Parametros------: cCodCli := Código do Cliente do Pedido
----------------: cLojCli := Código da Loja do Cliente do Pedido
----------------: cNumPed := Código do Pedido
Retorno---------: lRet := Informa se o Pedido atual 'cabe' no Limite disponível ( .F. = Sim / .T. = Não )
===============================================================================================================================
*/
User Function AOMS112Y( cCodCli , cLojCli , cNumPed )

Local cAlias	:= GetNextAlias()
Local _cQuery	:= ""
Local nValPed	:= 0

//-- Recupera o valor do Pedido atual para verificar se 'cabe' no Limite de Crédito disponível --//
_cQuery := " SELECT "
_cQuery += "     SUM( SZW.ZW_PRCVEN * SZW.ZW_QTDVEN ) AS VALPED "
_cQuery += " FROM "+ RetSqlName("SZW") +" SZW "
_cQuery += " WHERE "
_cQuery += "     SZW.ZW_IDPED	= '"+ cNumPed +"' "
_cQuery += " AND	SZW.ZW_CLIENTE	= '"+ cCodCli +"' "
_cQuery += " AND	SZW.ZW_LOJACLI	= '"+ cLojCli +"' "
_cQuery += " AND SZW.D_E_L_E_T_	= ' ' "

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
If (cAlias)->(!Eof()) .And. (cAlias)->VALPED > 0
	nValPed := (cAlias)->VALPED
EndIf

(cAlias)->( DBCloseArea() )

Return nValPed

/*
===============================================================================================================================
Programa--------: AOMS112GA
Autor-----------: Alexandre Villar
Data da Criacao-: 14/02/2014
Descrição-------: Atualiza status da avaliação da análise de Crédito do Pedido.
Parametros------: cNumPed := Código do Pedido
----------------: cFilAux := Filial do Pedido
----------------: cStsAva := Status da Avaliação do Pedido
----------------: cMotAva := Motivo da Avaliação do Pedido
----------------: cObsAva := Observação da Avaliação do Pedido
----------------: dLimite := Data limite da liberação completa
Retorno---------: lRet := Informa se a gravação da avaliação foi efetivada com sucesso ( .T. = Sim / .F. = Não )
===============================================================================================================================
*/
User Function AOM112GA( cNumPed , cFilAux , cStsAva , cMotAva , cObsAva, dLimite, nvalor )

Local lRet		:= .T.
Local _aarea	:= FWGetArea()
Local _cCoord   := ""
Local _cWF      := "1"
Default cNumPed	:= ""
Default cFilAux	:= ""
Default cStsAva	:= ""
Default cMotAva	:= ""
Default dLimite := ddatabase + 7
Default nvalor 	:= 0

If Empty(cNumPed) .Or. Empty(cFilAux) .Or. Empty(cStsAva) .Or. Empty(cMotAva)
	lRet := .F.
Else

	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	If SZW->( DBSeek( cFilAux + cNumPed ) )
		_cCoord:= Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")
		_cWF   := Posicione("SA3",1,xFilial("SA3")+_cCoord,"A3_I_WF")
		_cusername := UsrFullName(__cUserId)
		While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == cFilAux + cNumPed

			SZW->( RecLock( "SZW" , .F. ) )

			SZW->ZW_BLQLCR	:= cStsAva
			SZW->ZW_LIBL	:= dLimite
			SZW->ZW_LIBV	:= nvalor
			SZW->ZW_MOTBLCR	:= cMotAva
			SZW->ZW_DTAVAC	:= Date()
			SZW->ZW_HRAVAC	:= Time()
			SZW->ZW_USRAVAC	:= _cusername
			SZW->ZW_OBSAVAC	:= AllTrim(cObsAva) + " - AOMS112"

			If AllTrim(cStsAva) == "B"
				SZW->ZW_STATUS := "D"
			Else
				If _cWF == "2" //WF não é enviado ao Coord. somente ao Gerente caso tenha Preço fora da Tabela
					SZW->ZW_BLOPRC = ' '
					SZW->ZW_STATUS = 'L'
					SZW->ZW_ENVWF   = 'C'
					SZW->ZW_NIVELWF = 'P'
				Else
					SZW->ZW_BLOPRC  = ' '
					SZW->ZW_STATUS  = 'A'
					SZW->ZW_ENVWF   = ' '
					SZW->ZW_NIVELWF = ' '
					SZW->ZW_I_HTML  = ' '
				EndIf
			EndIf

			SZW->( MSUnLock() )

			SZW->( DBSkip() )

		EndDo

	Else
		lRet := .F.
	EndIf

EndIf

FWRestArea(_aarea)

Return(lRet)

/*
===============================================================================================================================
Programa--------: AOMS112GC5
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Gera pedido de venda real
Parametros------: cFlVer - Filial do pedido de venda / _lAutoref - execução de pedidos múltiplos
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112GC5( cFlVer , _oSay, _lAutoref , _lTela )

	Local cCli			:= ""
	Local cLojCli		:= ""
	Local cTipCli		:= ""
	Local cCond			:= ""
	Local cVend1		:= ""
	Local cTab			:= ""
	Local nDesp			:= 0
	Local cMenNf		:= ""
	Local cTpFret		:= ""
	Local cObs			:= ""
	Local cTransp		:= ""
	Local cHr			:= ""
	Local cSenha		:= ""
	Local dEntr			:= CtoD("")
	Local cIdPed		:= ""
	Local cBlPrc		:= ""
	Local cCodUsu		:= ""
	Local aItens		:= {}
	Local nVlrTot		:= 0
	Local nVlDesc1		:= 0
	Local nVlDesc2		:= 0
	Local nVlDesc3		:= 0
	Local nVlDesc4		:= 0
	Local _ntotvlr		:= 0
	Local _ntotqtd		:= 0
	Local _cFilPro 		:= cFlVer
	Local _lok 			:= .F.
	Local _cEvento      := " "
	Local _lRet			:= .T.
	Local _nnl			:= 0
	Local _ty			:= 0
	Local _cErro        := ""
	Local _cEnvRDC		:= "N"
    
	Local _cOperFret := SuperGetMV("IT_OPERFRE",.T.,"")
	Local _dDtCalcFr := Ctod(SuperGetMV("IT_DTCALCF",.T.,"23/06/2022"))
	Local _nDescPTon := 0
	Local _lFob := .F.
	Local _cUF  := ""
	Local _cCodMunic := ""
	Local _nPesBrIte, _nPesBrTot
    Local _lProdBLqF  := .F.
	Private _cAOMS074VLD:= ' '
	Private cFilAtual	:= " "
	Private cPedGeraSC5	:= " "
	Private lMsErroAuto	:= .F.
	Private lMsHelpAuto	:= .T.
	Private nSaveSX8	:= 0
	Private _aLog		:= {}
	Private _cTpAgenda  := " "
	Private aCorrigeItem:= {}//Array para Corrigir a sequencia do campo C6_ITEM quando grava com '00'

	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	If SZW->( DBSeek( cFlVer + AllTrim( cNumPed ) ) )

		cCli 		:= SZW->ZW_CLIENTE
		cLojCli		:= SZW->ZW_LOJACLI
		cTipCli		:= SZW->ZW_TIPOCLI
		cCond		:= AOMS1125()
		cVend1		:= SZW->ZW_VEND1
		cTab		:= ""
		nDesp		:= SZW->ZW_DESPESA
		cMenNf		:= AllTrim( SZW->ZW_MENNOTA )
		cTpFret		:= SZW->ZW_TPFRETE
		cObs		:= SZW->ZW_OBSCOM
		cTransp		:= SZW->ZW_TRANSP
		cHr			:= SZW->ZW_HOREN
		cSenha		:= SZW->ZW_SENHA
		cTp			:= IIf(SZW->ZW_TIPO == "05","42",SZW->ZW_TIPO) //SubStr(cTipPed,1,2)
		dEntr		:= SZW->ZW_FECENT

		If SZW->ZW_I_AGEND == 'P'
			If month(date()) != 12
				dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+1)))+"0101")-1
			Else
				dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+2)))+"0101")-1
			EndIf
		EndIf

		If SZW->ZW_I_AGEND $ 'I/O'//I=Imediata //O=Agendada pelo Op.Log.
			_cFilCarreg := SZW->ZW_FILIAL
			If !Empty(SZW->ZW_FILPRO) .And. !(AllTrim(SZW->ZW_FILPRO)=='0')
				_cFilCarreg := SZW->ZW_FILPRO
			EndIf

			//cTipoAg		:= SZW->ZW_I_AGEND+" - IMEDIATO"
			dDtEnt := DATE()+u_omsvldent(DATE(),SZW->ZW_CLIENTE,SZW->ZW_LOJACLI,SZW->ZW_FILIAL,cNumPed,1,.F.,_cFilCarreg,SZW->ZW_TIPO,SZW->ZW_TPVENDA)

		EndIf

	    cTipoAg:=SZW->ZW_I_AGEND+" - "+(U_TipoEntrega(SZW->ZW_I_AGEND))

		cIdPed		:= SZW->ZW_IDPED
		cBlPrc		:= SZW->ZW_BLOPRC
		If _lTela
			cCodUsu		:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
		Else
			cCodUsu		:= "SISTEMA"
		EndIf
		_cchep 		:= Posicione("SA1",1,xFilial("SA1")+ccli+cLojCli,"A1_I_CCHEP")
		cTipCar		:= If( !Empty(_cchep) , "1 - Paletizada" , "2 - Batida" )
		nQtdCha		:= SZW->ZW_CHAPA
		cHrDes		:= SZW->ZW_HORDES
		nCusDes		:= SZW->ZW_CUSDES
		_cEvento    := SZW->ZW_EVENTO
		_cTpAgenda  := If(SZW->ZW_I_AGEND$"PIAMO",SZW->ZW_I_AGEND,"I")

		If SZW->ZW_FILPRO != '0 ' .And. !Empty(SZW->ZW_FILPRO) .And. SZW->ZW_FILPRO != SZW->ZW_FILIAL
			_cFilpro := SZW->ZW_FILPRO//TROCA NF
		Else
			_cFilpro := SZW->ZW_FILIAL// FATURANDO E CARREGANDO NA MESMA FILIAL
		EndIf

		//Localiza tabela de preço do pedido
		_cvend2 := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")
		_cvend3 := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_GEREN")

		_aItensLock:={}
		_llibpreco := .F.

		SBZ->(DBSetOrder(1)) // BZ_FILIAL+BZ_COD

		DBSelectArea("SZW")
		_lTrocaArmTN:=.F.//Troca o armazem para o da filial nova

		If _cfilpro $ "90/40" .Or. (!Empty(SZW->ZW_FILPRO) .And. Val(SZW->ZW_FILPRO) != 0 .And. SZW->ZW_FILPRO != SZW->ZW_FILIAL )
			U_AOMS112H(cFlVer , cIdPed ,_cfilpro) //Somente tratar para Filial 90/40  que tem produção em Itapetininga / 2 coracoes e troca nota para tratar armaem 36
		EndIf        
    
		//Reordena pedido por código de produto para diminuir possibilidades de deadlock futuro
		SZW->( DBSetOrder(16) )
		SZW->( DBSeek( cFlVer + cIdPed ) )
		_aposis := {}

		While SZW->ZW_FILIAL == cFlVer .And. SZW->ZW_IDPED == cIdPed

			aAdd(_aposis,SZW->(Recno()))
			SZW->(DBSkip())

		EndDo

		_nnl := 1
		_cseq := "A1"//TROCA A SEQUENCIA PARA LETRA PARA QUANDO NUMERAR CERTO NÃO DAR CHAVE DUPLICADA

		For _nnl := 1 to Len(_aposis)

			SZW->(DBGoTo(_aposis[_nnl]))
			RecLock("SZW", .F.)
			SZW->ZW_ITEM = _cseq
			If _lTrocaArmTN
			   SZW->ZW_LOCAL:=Posicione("SBZ",1,_cFilpro+SZW->ZW_PRODUTO,"BZ_LOCPAD")
			EndIf
			_cseq := Soma1(_cseq)
			SZW->(MSUnLock())

		Next

		For _nnl := 1 to Len(_aposis)

			SZW->(DBGoTo(_aposis[_nnl]))
			RecLock("SZW", .F.)
			SZW->ZW_ITEM = AllTrim(Str(_nnl))
			SZW->(MSUnLock())

		Next

        ZBS->(DBSetOrder(1)) 

		SZW->( DBSetOrder(16) )
		SZW->( DBSeek( cFlVer + cIdPed ) )
        
		_nPesBrIte := 0
		_nPesBrTot := 0
		aCorrigeItem:={}//Array para Corrigir a sequencia do campo C6_ITEM quando grava com '00'
        
		_lProdBLqF := .F. // Indica se houve bloqueio de produto por filial.

		While SZW->( !Eof() ) .And. cFlVer + cIdPed == SZW->( ZW_FILIAL + ZW_IDPED )

			If _oSay <> NIL
			   _oSay:cCaption := ('Lendo Item ' + SZW->ZW_ITEM)
			   ProcessMessages()
			EndIf

			nFatConv:= GetAdvFVal( "SB1" , "B1_CONV"	, xFilial("SB1") + SZW->ZW_PRODUTO	, 1 , "" )
			cTpConv	:= GetAdvFVal( "SB1" , "B1_TIPCONV"	, xFilial("SB1") + SZW->ZW_PRODUTO	, 1 , "" )
			nNewFat	:= GetAdvFVal( "SB1" , "B1_I_FATCO"	, xFilial("SB1") + SZW->ZW_PRODUTO	, 1 , "" )

			// Calcula o Peso Total Bruto do Pedido do Portal.
			_nPesBrIte := GetAdvFVal( "SB1" , "B1_PESBRU"	, xFilial("SB1") + SZW->ZW_PRODUTO	, 1 , "" ) 
		    _nPesBrTot += (_nPesBrIte * SZW->ZW_QTDVEN)

			// Verifica se existe regra de TES inteligente para o cliente e produto, caso não exista, o sistema retorna para a tela inicial
			AOM112VerTES( cCli , cLojCli , cTp , cIdPed) 

		    aAdd(_aItensLock,{SZW->ZW_PRODUTO,SZW->ZW_LOCAL}) // _cAramazem
    
		    If cTpConv == "M"
		    	nQtd2UM:= IIf( nFatConv == 0 , nNewFat * SZW->ZW_QTDVEN	, nFatConv * SZW->ZW_QTDVEN	)
		    Else
		    	nQtd2UM:= IIf( nFatConv == 0 , SZW->ZW_QTDVEN / nNewFat	, SZW->ZW_QTDVEN / nFatConv	)
		    EndIf
            
			aAdd(aCorrigeItem,{SZW->ZW_PRODUTO , StrZero( Val( AllTrim(SZW->ZW_ITEM) ) , 2 )  } )

		    aIt := {{ "C6_FILIAL", _cFilPro					   		, Nil },;
			{ "C6_ITEM"   	, StrZero( Val( AllTrim(SZW->ZW_ITEM) ) , 2 ), Nil },;
			{ "C6_PRODUTO"	, SZW->ZW_PRODUTO						, Nil },;
			{ "C6_QTDVEN" 	, SZW->ZW_QTDVEN						, Nil },;
			{ "C6_UNSVEN" 	, nQtd2UM								, Nil },;
			{ "C6_PEDCLI" 	, StrTran( StrTran( StrTran( SZW->ZW_PEDCLI , "ª" , "" ) , "º" , "" ) , CHAR(176) , "" ) , Nil },;
			{ "C6_I_LIBPE" 	, SZW->ZW_MLIBPRC						, Nil },;
			{ "C6_PRCVEN" 	, SZW->ZW_PRCVEN						, Nil },;
			{ "C6_I_VLIBP" 	, SZW->ZW_PRCVEN						, Nil },;
			{ "C6_I_VLTAB" 	, SZW->ZW_PRUNIT						, Nil },;
            { "C6_I_PRMIN" 	, SZW->ZW_I_PRMP						, Nil },;
			{ "C6_PRUNIT" 	, 0              						, Nil },;
			{ "C6_I_BLPRC"  , SZW->ZW_BLOPRC						, Nil },;
			{ "C6_I_DLIBP"  , SZW->ZW_DLIBP							, Nil },;
			{ "C6_I_PLIBP"  , SZW->ZW_PLIBP							, Nil },;
			{ "C6_I_ULIBP"  , SZW->ZW_ULIBP							, Nil },;
			{ "C6_I_PLIBP"  , SZW->ZW_PLIBP							, Nil },;
			{ "C6_I_LLIBP"  , SZW->ZW_LOJACLI						, Nil },;
			{ "C6_I_CLILP"  , SZW->ZW_CLIENTE						, Nil },;
			{ "C6_I_QTLIP"  , SZW->ZW_QTDVEN						, Nil },;
			{ "C6_I_LLIBB"  , SZW->ZW_LOJACLI						, Nil },;
			{ "C6_I_CLILB"  , SZW->ZW_CLIENTE						, Nil },;
			{ "C6_I_QLIBB"  , SZW->ZW_QTDVEN						, Nil },;
			{ "C6_I_MOTLB"  , SZW->ZW_I_MTBON						, Nil },;
			{ "C6_I_PLIBB"  , SZW->ZW_I_DLIBE + 30					, Nil },;
			{ "C6_I_DLIBB"  , SZW->ZW_I_DLIBE						, Nil },;
			{ "C6_I_MOTLP"  , SZW->ZW_MOTLP							, Nil },;
			{ "C6_LOCAL"    , SZW->ZW_LOCAL							, Nil },;
			{ "C6_I_FXPES"  , SZW->ZW_I_FXPES						, Nil },;
			{ "C6_ENTREG" 	, dDtEnt	                            , Nil },;
			{ "C6_ITEMPC"   , StrZero( Val( AllTrim(SZW->ZW_ITEM) ) , 2 )	, Nil },;
			{ "C6_NUMPCOM"  , StrTran( StrTran( StrTran( SZW->ZW_PEDCLI , "ª" , "" ) , "º" , "" ) , CHAR(176) , "" ) , Nil }}
		
	    	If SZW->(FIELDPOS( "ZW_I_ITDW" )) <>  0
	    		aAdd(aIt,{ "C6_I_ITDW",SZW->ZW_I_ITDW,Nil })
	    	EndIf

			aAdd(aIt,{ "C6_I_KIT" , SZW->ZW_KIT ,Nil }) 

	    	aAdd( aItens , aIt )
    
	    	nVlDesc1	:= SZW->ZW_DESC1
	    	nVlDesc2	:= SZW->ZW_DESC2
	    	nVlDesc3	:= SZW->ZW_DESC3
	    	nVlDesc4	:= SZW->ZW_DESC4
	    	nVlrTot		:= nVlrTot + ( SZW->ZW_QTDVEN * SZW->ZW_PRCVEN )
	    	_ntotvlr  += SZW->ZW_PRCVEN
	    	_ntotqtd  += SZW->ZW_QTDVEN
    
	    	If SZW->ZW_BLOPRC == 'L'
    
	    		_llibpreco := .T.
    
	    	EndIf
    
	    	SZW->( DBSkip() )
	    EndDo

	SZW->( DBSetOrder(1) )

	//Se teve problema de TES avisa e volta para tela inicial
	If Len(_aLog) > 0//_aLog gravado na funcao AOM112VerTES()

		If _lAutoref

			SZW->( DBSetOrder(1) )
			SZW->( DBSeek( _cFilpro + cNumped ) )

			SA1->(DBSetOrder(1))
			SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

			//Monta produtos que apresentaram problemas
			_cprodutos := ""
			_cDetalhes := ""
			For _ty := 1 to Len(_alog)
				_cprodutos += "[ "+AllTrim( _alog[_ty][7] )+" ] "
				_cDetalhes += AllTrim( _alog[_ty][4] )
			Next

			//_cprodutos := SubStr(_cprodutos,1,Len(_cprodutos)-3)

			aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),_cFilPro,cNumPed,SZW->ZW_CLIENTE+"/"+SZW->ZW_LOJACLI+" - "+AllTrim(SA1->A1_NOME),"Foram encontrado(s) produto(s) sem regra de TES INTELIGENTE: " + _cprodutos,_cDetalhes})

		Else

			_cMen:="Foram encontrado(s) produto(s) sem regra de TES INTELIGENTE cadastrada para a filial de criação do pedido de venda, "				+;
				"desta forma não sera possível prosseguir com a efetivação, favor informar ao responsável pela inclusão das regras de TES INTELIGENTE "	+;
				"do problema encontrado."

			U_ITMsg( _cMen, 'Atenção!',, 1   )

			U_ITListBox( 'Lista de produtos com sem TES Inteligente, Pedido: '+AllTrim(cIdPed)+' (AOMS112)' ,;
				{'Filial','Operação','Cliente/Remessa','Est. Orig. Dest.','Suframa/Simples/Contr.',"Armazem",'Produto'} , _aLog , .T. , 1 ,;
				"Abaixo segue a relação de produtos que se encontram sem TES Inteligente: " )

		EndIf

		Return .F.

	EndIf//If Len(_aLog) > 0

	DBSelectArea("SZW")
	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( cFlVer + cIdPed ) )

	//Se é tipo agenda aguardando agendamento força data de entrega para último dia do ano
	If	AllTrim(_cTpAGenda) == 'P'

		If month(date()) != 12

			dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+1)))+"0101")-1

		Else

			dDtEnt := SToD(AllTrim(Str((YEAR(DATE())+2)))+"0101")-1

		EndIf

	EndIf

	If cvincula == "S"
		_cEnvRDC := "V"
	Else
		_cEnvRDC := "N"
	EndIf

	_ccondi := SubStr(AOMS1125(),1,3)

	// Calcula desconto por tonelada para fretes Fob.
	_lFob      := Posicione("SA1",1,xFilial("SA1") + cCli + cLojCli ,"A1_I_FOB")
	_nDescPTon := 0

	If _lFob .And. AllTrim(cTpFret) $ "F/D" .And. !(SZW->ZW_TIPO $ _cOperFret) .And. DToS(Date()) >= DToS(_dDtCalcFr)  //  M->C5_TPFRETE   // M->C5_I_OPER

		_cUF       := Posicione("SA1",1,xFilial("SA1") + cCli + cLojCli ,"A1_EST")
		_cCodMunic := Posicione("SA1",1,xFilial("SA1") + cCli + cLojCli ,"A1_COD_MUN")

		_nDescPTon := U_M410BDES(_cFilPro , _cUF, SZW->ZW_TIPO ,_cCodMunic) // Retorna o desconto por tonelada para pedidos Fob.

		If _nDescPTon > 0
			_nDescPTon := ((_nPesBrTot /1000 ) * _nDescPTon)
		EndIf
	EndIf

	If _nDescPTon = 0
		_nDescPTon := SZW->ZW_FOBDESC
	EndIf

	aCabec := {	{ "C5_FILIAL"	, _cFilPro	, Nil },;
		{ "C5_TIPO"   	, "N"		, Nil },;
		{ "C5_I_OPER" 	, IIf(AllTrim(SZW->ZW_TIPO) == _cOperFat,_cOperRemessa,SZW->ZW_TIPO)	, Nil },;
		{ "C5_CLIENTE"	, cCli		, Nil },;
		{ "C5_LOJACLI"	, cLojCli	, Nil },;
		{ "C5_TIPOCLI"	, cTipCli 	, Nil },;
		{ "C5_VEND1"	, cVend1	, Nil },;
		{ "C5_EMISSAO"	, Date()	, Nil },;
		{ "C5_I_HREMI"	, Time()	, Nil },;
		{ "C5_DESC1"	, nVlDesc1	, Nil },;
		{ "C5_DESC2"	, nVlDesc2	, Nil },;
		{ "C5_DESC3"	, nVlDesc3	, Nil },;
		{ "C5_DESC4"	, nVlDesc4	, Nil },;
		{ "C5_DESPESA" 	, nDesp	    , Nil },;
		{ "C5_MENNOTA" 	, cMenNf	, Nil },;
		{ "C5_TPFRETE" 	, cTpFret	, Nil },;
		{ "C5_I_OBPED" 	, cObs		, Nil },;
		{ "C5_TRANSP" 	, cTransp	, Nil },;
		{ "C5_I_HOREN" 	, cHrEnt	, Nil },;
		{ "C5_I_SENHA" 	, cSenha	, Nil },;
		{ "C5_I_DTENT" 	, dDtEnt	, Nil },;
		{ "C5_I_IDPED" 	, cIdPed	, Nil },;//TRB->NUMPED - SZW->ZW_IDPED - TRBF->NUMPED
		{ "C5_I_CDUSU" 	, cCodUsu	, Nil },;
		{ "C5_I_TIPCA" 	, cTipCar	, Nil },;
		{ "C5_I_CHAPA" 	, nQtdCha	, Nil },;
		{ "C5_I_HORDE" 	, cHrDes	, Nil },;
		{ "C5_I_CUSDE"	, nCusDes	, Nil },;
		{ "C5_I_EVENT"	, _cEvento	, Nil },;
		{ "C5_I_AGEND"	, _cTpAGenda	  , Nil },;
		{ "C5_CONDPAG"	, _ccondi         , Nil },;
		{ "C5_I_TPVEN"  , SZW->ZW_TPVENDA , Nil },;
		{ "C5_I_DTAVA"  , SZW->ZW_DTAVAC  , Nil },;
		{ "C5_I_HRAVA"  , SZW->ZW_HRAVAC  , Nil },;
		{ "C5_I_ORTBP"  , SZW->ZW_REGRA   , Nil },;
		{ "C5_I_TAB"    , SZW->ZW_TABELA  , Nil },;
		{ "C5_DESCONT"  , _nDescPTon      , Nil },; // SZW->ZW_FOBDESC
	    { "C5_I_OBS"    , SZW->ZW_I_OBS   , Nil },;
		{ "C5_I_DLIBG"  , SZW->ZW_I_DLIBG , Nil },;
		{ "C5_I_HLIBG"  , SZW->ZW_I_HLIBG , Nil },;
		{ "C5_I_ENVRD"  , _cEnvRDC        , Nil },;
		{ "C5_I_USRAV"  , SZW->ZW_USRAVAC , Nil }}
		
		aAdd( aCabec,{ "C5_I_RECSA" , SZW->ZW_I_RECSA, Nil })

	//Liberação de preço - Só grava se teve liberação
	If  SZW->ZW_BLOPRC == "L"

		aAdd( aCabec,{ "C5_I_BLPRC"  	, SZW->ZW_BLOPRC, Nil })
		aAdd( aCabec,{ "C5_I_DTLIP"  	, SZW->ZW_DLIBP	, Nil })
		aAdd( aCabec,{ "C5_I_HLIBP"  	, SZW->ZW_HLIBP	, Nil })
		aAdd( aCabec,{ "C5_I_PLIBP"  	, SZW->ZW_PLIBP	, Nil })
		aAdd( aCabec,{ "C5_I_ULIBP"  	, SZW->ZW_ULIBP	, Nil })
		aAdd( aCabec,{ "C5_I_LLIBP"  	, SZW->ZW_LLIBP	, Nil })
		aAdd( aCabec,{ "C5_I_MLIBP"  	, SZW->ZW_MLIBP	, Nil })
		aAdd( aCabec,{ "C5_I_MOTLP"  	, SZW->ZW_MOTLP	, Nil })
		aAdd( aCabec,{ "C5_I_CLILP"  	, SZW->ZW_CLILP	, Nil })
		aAdd( aCabec,{ "C5_I_QLIBP"  	, _ntotqtd		, Nil })
		aAdd( aCabec,{ "C5_I_VLIBP"  	, _ntotvlr		, Nil } )

	EndIf

	//Liberação de crédito - Só grava se teve liberação
	If SZW->ZW_BLQLCR == "L" .Or. SZW->ZW_BLQLCR == "C"

		aAdd( aCabec,{"C5_I_BLCRE"  , "L"			    , Nil })
		aAdd( aCabec,{"C5_I_LIBC "  , IIf(SZW->ZW_BLQLCR == "L",0,2)		, Nil })
		aAdd( aCabec,{"C5_I_DTLIC"  , SZW->ZW_I_LIBCD	, Nil })
		aAdd( aCabec,{"C5_I_LIBCD"  , SZW->ZW_I_LIBCD	, Nil })
		aAdd( aCabec,{"C5_I_LIBCT"  , SZW->ZW_I_LIBCT	, Nil })
		aAdd( aCabec,{"C5_I_LIBCA"  , SZW->ZW_I_LIBCA	, Nil })
		aAdd( aCabec,{"C5_I_MOTBL"  , SZW->ZW_I_MOTBL	, Nil })
		aAdd( aCabec,{"C5_I_LIBL"   , SZW->ZW_LIBL		, Nil })
		aAdd( aCabec,{"C5_I_LIBV"   , SZW->ZW_LIBV		, Nil })
		aAdd( aCabec,{"C5_I_LIBCV"  , nVlrTot	        , Nil })

	EndIf

	//Liberação de bonificação - Só grava se teve liberação e ainda é bonificação
	//If SZW->ZW_BLOQ == "L" .And. SZW->ZW_TIPO == '10'
	If SZW->ZW_BLOQ == "L" .And. (SZW->ZW_TIPO $ '10/24/05' .Or.  SZW->ZW_TPFRETE = "F" )
		aAdd( aCabec,{ "C5_I_BLOQ"  , SZW->ZW_BLOQ, Nil })
		aAdd( aCabec,{ "C5_I_DLIBE"  , SZW->ZW_I_DLIBE, Nil })
		aAdd( aCabec,{ "C5_I_HLIBE"  , SZW->ZW_I_HLIBE, Nil })
		aAdd( aCabec,{ "C5_I_VLIBB"  , _ntotvlr, Nil })
		aAdd( aCabec,{ "C5_I_QLIBB"  , _ntotqtd, Nil })
		aAdd( aCabec,{ "C5_I_LLIBB"  , cLojCli, Nil })
		aAdd( aCabec,{ "C5_I_CLILB"  , cCli, Nil })
		aAdd( aCabec,{ "C5_I_MOTLB"  , SZW->ZW_I_MOTLB, Nil })
		aAdd( aCabec,{ "C5_I_ULIBB"  , SZW->ZW_I_ULIBB, Nil })
	EndIf

	If SZW->(FIELDPOS("C5_I_OBSAV")) # 0//Campo da avaliacao NOVO
		aAdd( aCabec, {"C5_I_OBSAV"  , SZW->ZW_OBSAVAC, Nil }  )
	EndIf
	If SZW->(FIELDPOS( "ZW_I_PEDDW" )) <>  0
		aAdd(aCabec,{ "C5_I_PEDDW",SZW->ZW_I_PEDDW,Nil })
	EndIf

	_cOperTri   := Space(1)  // Esta variável será utilizada no fonte MT410TOK para peencher o campo operação triangular.
	_cCodClien  := Space(6)  // Esta variável será utilizada no fonte MT410TOK para peencher o campo codigo Cliente/Venda.
	_cLojaClie  := Space(4)  // Esta variável será utilizada no fonte MT410TOK para peencher o campo Loja Cliente/Venda.

	If _cFilPro <> cFlVer//_cFilPro sempre esta preenchido PQ inicio com a cFlVer

		M->C5_I_TRCNF:="S"   //Variavel usada no gatilho do C6_PRCVEN
		M->C5_I_FILFT:=cFlVer//Variavel usada no gatilho do C6_PRCVEN

		aAdd( aCabec, { "C5_I_TRCNF", "S"	  , Nil } )
		aAdd( aCabec, { "C5_I_FILFT", cFlVer  , Nil } )
		aAdd( aCabec, { "C5_I_FLFNC", _cFilPro, Nil } )

	Else

		M->C5_I_TRCNF:="N"   //Variavel usada no gatilho do C6_PRCVEN
		M->C5_I_FILFT:=cFlVer//Variavel usada no gatilho do C6_PRCVEN

		aAdd( aCabec, { "C5_I_TRCNF", "N"  , Nil } )
		aAdd( aCabec, { "C5_I_FILFT", " "  , Nil } )
		aAdd( aCabec, { "C5_I_FLFNC", " "  , Nil } )

	EndIf

	// Tratamento da Operação Tria zngular
	If !Empty(SZW->ZW_CLIREM) .And. LEFT(cTipPed,2) $ _cOperTriangular
		_cOperTri   := ""//"R"
		_cCodClien  := ""//SZW->ZW_CLIREM
		_cLojaClie  := ""//SZW->ZW_LOJEN

		aAdd( aCabec, { "C5_I_OPTRI","R"           , Nil})//TRATAMENTO DA OPERCAO TRIAGULAR
		aAdd( aCabec, { "C5_I_CLIEN",SZW->ZW_CLIREM, Nil})//Depois da Mudança da Op Triangular de  05 para 42. Este campo agora é o cliente de faturamento.
		aAdd( aCabec, { "C5_I_LOJEN",SZW->ZW_LOJEN , NiL})
	EndIf
	// Tratamento da Operação Triangular


	Begin Sequence
		Begin Transaction


			//Valida se já não existe um pedido na c5 com esse idped
			_cQuery := " SELECT C5_NUM , C5_EMISSAO "
			_cQuery += " FROM "+ RetSqlName("SC5") +" SC5 "
			_cQuery += " WHERE  SC5.C5_I_IDPED	= '"+ AllTrim(cNumPed) +"' "
			_cQuery += " AND SC5.D_E_L_E_T_	= ' ' "

			cAliast := getnextalias()

			If Select(cAliast) > 0
				(cAliast)->( DBCloseArea() )
			EndIf

			DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , cAliast , .T. , .F. )

			DBSelectArea(cAliast)
			(cAliast)->( DBGoTop() )

			If (cAliast)->(!Eof())
				_lok := .F.
				_cAOMS074VLD:="Pedido ja foi Efetivado, esta no Protheus no Código Ped.: " +(cAliast)->C5_NUM + " / Emissao: "+DToC(SToD((cAliast)->C5_EMISSAO))+". Por favor entrar em contato com TI."//})
				Disarmtransaction()
				Break
			EndIf

			(cAliast)->( DBCloseArea() )

			//Valida se pedido está disponível para lock e se não foi efetivado por outra estação durante as validações
			DBSelectArea("SZW")
			SZW->( DBSetOrder(1) )
			SZW->( DBSeek( cFlVer + cNumPed ) )
            _aRecProdSZW:={}
			While SZW->(!Eof()).AND.cNumPed == SZW->ZW_IDPED

				If !SZW->(MsRLock(SZW->(RECNO()))) .Or. !Empty(SZW->ZW_NUMPED) .Or. SZW->ZW_STATUS == "I"
					_lok := .F.
					Disarmtransaction()
					Break
				EndIf
                aAdd(_aRecProdSZW,{SZW->ZW_PRODUTO,SZW->(RECNO())," "})
				SZW->(DBSkip())

			EndDo

			cFilAtual:= cFilAnt // Filial que esta logado
			cFilAnt	 := _cFilPro  // Filial que o pedido do portal esta selecionado para efetivacao
			_cErroPV := ""

			//Guarda parâmetros
			_MV_PAR01 := MV_PAR01
			_MV_PAR02 := MV_PAR02
			_MV_PAR03 := MV_PAR03
			_MV_PAR04 := MV_PAR04
			_MV_PAR05 := MV_PAR05
			_MV_PAR06 := MV_PAR06

			If _lAutoref
				_cmens := "Gerando pedido " + StrZero(_nni,4) + " de " + StrZero(_ntot,4)
			Else
				_cmens := "GERANDO O PEDIDO DE VENDA PARA O PEDIDO DO PORTAL " + cIdPed
			EndIf

         _lMsgEmTela  := .F.
			_cAOMS074    :="AOMS112"//DesAtiva o _lMsgEmTela := .F. no MT410TOK.PRW
			_cAOMS074Vld :=""//Pega as mensagens de erro
			_cErro       := " "

			//Siga auto de inclusao de pedido de venda
			If _lTela
				FWMsgRun( , {|| MSEXECAUTO( {|x,y,z| Mata410(x,y,z) } , aCabec , aItens , 3 ) }, "MSEXECAUTO() - AGUARDE...", _cmens  )
			Else
				MSEXECAUTO( {|x,y,z| Mata410(x,y,z) } , aCabec , aItens , 3 )
			EndIf
         _lMsgEmTela  := .T.

			_lLiberou:=.T.
			If lMsErroAuto
				If !_lAutoref
					_cErro:=" MostraErro: ["+MostraErro()+"]"
				Else
					_cErro:=" MostraErro: ["+MostraErro("\data\Italac\AOMS112\","AOMS112_MostraErro_"+AllTrim(cNumPed)+".LOG")+"]"
				EndIf
			Else

				SA3->(DBSetOrder(1))
				If SA3->(DBSeek(xFilial("SA3")+LEFT(SC5->C5_VEND1,Len(SA3->A3_COD)) )) .And. SA3->A3_I_ESTOQ = "S"
			       
				   If !(_lLiberou:=Ver_Lib_PV(SC5->C5_FILIAL+SC5->C5_NUM,_aRecProdSZW))//Pedidos Vendas via Pedido portal para Broker que validar Estoque
	   			   
				      aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),SC5->C5_FILIAL,SC5->C5_NUM,AllTrim(SC5->C5_VEND1)+"-"+SA3->A3_NOME,"Falha na LIBERACAO DO ESTOQUE (SC9) do pedido de vendas."})
					  _cAOMS074VLD:="Não foi possivel a LIBERACAO DO ESTOQUE (SC9) de todos os itens do pedido de vendas."
				   Else
	   			       aAdd(_aResults, {LoadBitmap(GetResources(),"BR_AZUL"),SC5->C5_FILIAL,SC5->C5_NUM,AllTrim(SC5->C5_VEND1)+"-"+SA3->A3_NOME,"LIBERACAO DO ESTOQUE (SC9) do pedido de vendas COM SUCESSO."})
				   EndIf
				EndIf
			
			EndIf
			//Restaura parâmetros
			MV_PAR01 := _MV_PAR01
			MV_PAR02 := _MV_PAR02
			MV_PAR03 := _MV_PAR03
			MV_PAR04 := _MV_PAR04
			MV_PAR05 := _MV_PAR05
			MV_PAR06 := _MV_PAR06

			cFilGeraSC5	:= SC5->C5_FILIAL
			cPedGeraSC5	:= SC5->C5_NUM
			cFilAnt		:= cFilAtual
			
			SZW->( DBSetOrder(1) )
			SZW->( DBSeek( cFlVer + cNumPed ) )
			cNumPedMostra:= cNumPed
		    If !Empty(SZW->ZW_PEDIMPO)
               cNumPedMostra:=AllTrim(cNumPed)+" ["+AllTrim(SZW->ZW_PEDIMPO)+"]"
		    EndIf


			If Empty( cPedGeraSC5 ) .Or. AllTrim( cFilGeraSC5 ) <> AllTrim( _cFilPro ) .OR.;
			            lMsErroAuto .Or. !Empty(_cErroPV) .Or. !_lLiberou

				If ( __lSx8 )

					While ( GetSX8Len() > nSaveSX8 ) // Retorna a numeração caso não confirme
						RollBackSX8()
					EndDo

				EndIf

				_lok := .F.
				DisarmTransaction()

				If !_lLiberou
				   SA3->(DBSeek(xFilial("SA3")+LEFT(SZW->ZW_VEND1,Len(SA3->A3_COD)) ))
				   For  _nnl := 1 TO Len(_aRecProdSZW)
				       If _aRecProdSZW[_nnl,2] > 0 
		                  SZW->( DBGoTo(_aRecProdSZW[_nnl,2]) )
 		                  SZW->( RecLock( "SZW" , .F. ) )
						  If !Empty(_aRecProdSZW[_nnl,3])
		                     SZW->ZW_MOTREC := AllTrim(SZW->ZW_MOTREC)+"["+_aRecProdSZW[_nnl,3]+"] "
				             aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFlVer,cNumPedMostra,AllTrim(SZW->ZW_VEND1)+"-"+SA3->A3_NOME,"Produto: "+AllTrim(SZW->ZW_PRODUTO)+" - "+AllTrim(GetAdvFVal("SB1","B1_DESC",xFilial("SB1")+SZW->ZW_PRODUTO,1,""))+" => SEM ESTOQUE."})
						  EndIf
		                  SZW->ZW_STATUS := "R"
		                  SZW->ZW_PEDIMPO:= " "
		                  SZW->ZW_NUMPED := " " 
		                  SZW->( MSUnLock() )
					   EndIf
					Next				
				EndIf


			Else

				_lefetivado := .T.

				If ( __lSx8 )

					While (GetSX8Len() > nSaveSX8) // Confirma a numeração
						ConfirmSX8()
					EndDo

				EndIf

				DBSelectArea("SZW")
				SZW->( DBSetOrder(1) )
				SZW->( DBSeek( cFlVer + cNumPed ) )

				While SZW->(!Eof()).AND.cNumPed == SZW->ZW_IDPED

					If _oSay <> NIL .And. _lTela
						_oSay:cCaption := ('Atualizando Item ' + SZW->ZW_ITEM)
						ProcessMessages()
					EndIf
					RecLock( "SZW" , .F. )

					SZW->ZW_STATUS  := "I"
					SZW->ZW_MUSEIMP := IIf(IsBlind(),"SISTEMA",FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3])
					SZW->ZW_HORAIMP := Time()
					SZW->ZW_DATAIMP := dDataBase
					SZW->ZW_NUMPED	:= SC5->C5_NUM
					SZW->ZW_I_MOTBL := " "
					SZW->( MSUnLock() )

					SZW->(DBSkip())

				EndDo

				SC5->( RecLock( "SC5", .F. ) )
				SC5->C5_CONDPAG :=  _ccondi
				SC5->C5_TABELA := ""
				SC5->( MSUnLock())
                

				If Select("TRBF") <> 0
					TRBF->( RecLock( "TRBF", .F. ) )
					TRBF->( DbDelete() )
					TRBF->( MSUnLock() )
					TRBF->(DBSkip())
				EndIf

				_lok := .T.

				//Gerar Pallet somente para Produtos Matinais Armazem 40
				//Não ativar FWMsgRun( , {|| GeraPedPallet() }, "MSEXECAUTO() - AGUARDE...", _cmens  )
			EndIf

		End Transaction
        
        If _lok .And. Len(aCorrigeItem) > 0 
           CorrigeItem(aCorrigeItem)// Verefica se o C6_ITEM esta igual ao ZW_ITEM, senão acerta - Parametros: aCorrigeItem,_cChavePed
           aCorrigeItem:={}
        EndIf

	End Sequence


	SB2->(DBUNLOCK())
	SA1->(DBUNLOCK())
	SB1->(MSUnLockALL())
	SB2->(MSUnLockALL())
	SA1->(MSUnLockALL())
	SC5->(MSUnLockALL())
	MSUnLockAll()

	If _lAutoref

		SZW->( DBSetOrder(1) )
		SZW->( DBSeek( cFlVer + cNumPed ) )

		SA1->(DBSetOrder(1))
		SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))
        cNumPedMostra:=cNumPed
		If !Empty(SZW->ZW_PEDIMPO)
           cNumPedMostra:=AllTrim(cNumPed)+" ["+AllTrim(SZW->ZW_PEDIMPO)+"]"
		EndIf
        
		If _lok

			aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERDE"),cFlVer,cNumPedMostra,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),"PEDIDO DE VENDA " + cPedGeraSC5 + "  CRIADO COM SUCESSO",""})

		Else

			aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),;                //01                                         
			                 cFlVer,;                                                  //02       
							 cNumPedMostra,;                                           //03              
							 AllTrim(SA1->A1_COD)+"-"+AllTrim(SA1->A1_NOME),;                   //04                                      
							 "Falha na criação do pedido de vendas: { " + _cAOMS074VLD + " }" ,;//05
							 "" })                                                     //06     
			If !Empty(_cErro)
				_aResults[Len(_aResults),6]:="Mostra Erro:  { " +  _cErro + " }"
			EndIf
			_lRet:=.F.
		EndIf

	Else

		If _lok .And. _lTela

			MsgInfo("Criado o Pedido de Venda "+ CHR(10) + CHR(13) +" Filial: "+ cFilGeraSC5 + CHR(10) + CHR(13) +"Pedido: "+ cPedGeraSC5 + " para o pedido do portal " + cNumPed , "Processo concluído")

		Else
			If _lTela
				U_ITMsg( 'Não foi possível gerar o Pedido de Venda! Verifique o registro de Log!' , 'Atenção!',If(!Empty(_cErroPV),_cErroPV,),1 )

				If Empty(_cErroPV)
					MostraErro()
				EndIf
			EndIf

			_lRet:=.F.

		EndIf

	EndIf

Else

	If _lAutoref

		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFlVer,cNumPed,"N/C",'Falha ao posicionar no pedido!'})

	Else
		If _lTela
			U_ITMsg(  'Falha ao posicionar no pedido!' , 'Atenção!' ,,1)
		EndIf

	EndIf

	_lRet:=.F.

EndIf


Return _lRet

/*
==============================================================================================================================================
Programa--------: AOM112VerTES()
Autor-----------: Alex Wallauer
Data da Criacao-: 22/02/2017
Descrição-------: Verifica se existe regra de TES inteligente para o cliente e produto, caso não exista, o sistema retorna para a tela inicial
Parametros------: cCli: coidgo do cliente  
----------------: cLojCli: loja do cliente
				  cTp - operação do pedido
				  cIdPed - id do pedido
				  cfilfat - filial de faturamento
Retorno---------: Nenhum
==============================================================================================================================================
*/
Static Function AOM112VerTES( cCli , cLojCli , cTp , cIdPed,cfilfat)

Local _cfilial := cfilant
Local _cArma,_cSuframa,_cTes,_cEstOri:=""

Default cfilfat := cfilant

SA1->(DBSetOrder(1))
If SA1->(DBSeek( xFilial("SA1") + cCli + cLojCli ))

	//posiciona na filial que vai gerar o pedido
	cfilant := SZW->ZW_FILIAL
	If !Empty(SZW->ZW_FILPRO) .And. Val(SZW->ZW_FILPRO) != 0
		cfilant := SZW->ZW_FILPRO
	EndIf

	Posicione("SM0",1,'01'+cFilant,"M0_NOMECOM")

	//Localiza armazém que será usado
	_cArma := SZW->ZW_LOCAL

	_cSuframa:=If(!Empty(SA1->A1_SUFRAMA),"S","N")
	_cCpoSN  :=If(SA1->A1_SIMPNAC="1","S","N")
	_cCpoCI  :=If(SA1->A1_CONTRIB="2","N","S")

	_cTes := u_selectTES(SZW->ZW_PRODUTO ,_cSuframa, SA1->A1_EST, (_cEstOri:=SM0->M0_ESTCOB), cCli, cLojCli, cTp,_cArma)

	If Empty(_cTes)
		_cMenTES:="Não existe nenhuma regra de TES Inteligente cadastrada para: "+CHR(13)+CHR(10)+;
					"Filial / Estado / Operacao: "+cFilAnt+" / "+_cEstOri+" / "+cTp+CHR(13)+CHR(10)+;
					"Cliente / Loja / Est. / Suframa: "+cCli+" / "+cLojCli+" / "+SA1->A1_EST+" / "+_cSuframa+CHR(13)+CHR(10)+;
					"Produto / Armazem: "+AllTrim(SZW->ZW_PRODUTO)+" / "+_cArma+CHR(13)+CHR(10)
		aAdd( _aLog ,{cfilant,cTp ,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),_cMenTES                   ,_cSuframa+" / "+_cCpoSN+" / "+_cCpoCI,_cArma,AllTrim(SZW->ZW_PRODUTO)+" - "+Posicione("SB1",1,xFilial("SB1")+SZW->ZW_PRODUTO,"B1_DESC")})
	EndIf

	//volta a filial a posição do ambiente
	cfilant := _cfilial
	Posicione("SM0",1,'01'+cFilant,"M0_NOMECOM")

	//Se mandou filial de faturamento diferente da filial de produção
	// testa TES para filial de faturamento também
	If cfilfat != cfilant

		//posiciona na filial que vai gerar o pedido
		_cfilori := cfilant
		cfilant := cfilfat
		Posicione("SM0",1,'01'+cFilant,"M0_NOMECOM")

		//Localiza armazém que será usado, no faturamento
		//do troca nota é sempre o armazém 40
		_cArma := '40'

		_cSuframa:=If(!Empty(SA1->A1_SUFRAMA),"S","N")
		_cCpoSN  :=If(SA1->A1_SIMPNAC="1","S","N")
		_cCpoCI  :=If(SA1->A1_CONTRIB="2","N","S")

		_cTes := u_selectTES(SZW->ZW_PRODUTO ,_cSuframa, SA1->A1_EST, (_cEstOri:=SM0->M0_ESTCOB), cCli, cLojCli, cTp,_cArma,"N")

		If Empty(_cTes)
			_cMenTES:="Não existe nenhuma regra de TES Inteligente cadastrada para: "+CHR(13)+CHR(10)+;
						"Filial / Estado / Operacao: "+cFilAnt+" / "+_cEstOri+" / "+cTp+CHR(13)+CHR(10)+;
						"Cliente / Loja / Est. / Suframa: "+cCli+" / "+cLojCli+" / "+SA1->A1_EST+" / "+_cSuframa+CHR(13)+CHR(10)+;
						"Produto / Armazem: "+AllTrim(SZW->ZW_PRODUTO)+" / "+_cArma+CHR(13)+CHR(10)
			aAdd(  _aLog ,{cfilant,cTp ,SA1->A1_COD + "/"+SA1->A1_LOJA + " - "+AllTrim(SA1->A1_NOME),_cMenTES                   ,_cSuframa+" / "+_cCpoSN+" / "+_cCpoCI,_cArma,AllTrim(SZW->ZW_PRODUTO)+" - "+Posicione("SB1",1,xFilial("SB1")+SZW->ZW_PRODUTO,"B1_DESC")})
		EndIf

		//volta a filial a posição do ambiente
		cfilant := _cfilori
		Posicione("SM0",1,'01'+cFilant,"M0_NOMECOM")


	EndIf

Else
	aAdd(  _aLog ,{SZW->ZW_FILIAL,cTp ,SA1->A1_COD + " "+SA1->A1_LOJA,SA1->A1_COD + " "+SA1->A1_LOJA + " - Cliente/Remessa não cadastrado",""                 ,_cArma,SZW->ZW_PRODUTO+" - "+Posicione("SB1",1,xFilial("SB1")+SZW->ZW_PRODUTO,"B1_DESC")})
EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS112H
Autor-----------: Julio de Paula Paz
Data da Criacao-: 21/03/2018
Descrição-------: Atualizar os armazens da tabela SZW para Filial 90, tendo como base a seguinte regra:
                  a) Se algum item da tabela SZW possuir o codigo do armazem contido no parametro IT_ARMAZTER, então
                     pegar o código do armazem do primeiro item que não esteja no parâmetro e gravar nos itens que possuem 
                     código do armazem contido no parâmetro IT_ARMAZTER.
                  b) Caso nenhum item da tabela SZW possua código do armazem contido no parâmetro IT_ARMAZTER, seguir a 
                     seguinte regra:
                      - Para quando ZW_LOCAL = B1_LOCPAD, gravar C6_LOCAL = BZ_LOCPAD
                      - Para quando ZW_LOCAL <> B1_LOCPAD, gravar C6_LOCAL = ZW_LOCAL
Parametros------: _cCodFil = Código da filial
                  _cIdPedido = Código do Pedido.
				  _cfilpro = FILIAL DE CARREGAMENTO
Retorno---------: Nenhum_cfilpro
===============================================================================================================================
*/
User Function AOMS112H(_cCodFil,_cIdPedido,_cfilpro)

Local _aRecnoSZW := {}
Local _cArmazemTerc := ""
Local _nI , cQry :=""
Local _lHaArmz36, _lSoArmaz36
Local _nPesoSZW, _nSomaPeso
Local _nPesoParam := 4000
Local _cRevenda := "N"
Local _cProexc := "00010225901;00010145901"
Local _cAlias := GetNextAlias()
Local _cArmzRevenda := "22"
Local _cArmzLocal   := "20"

_cFilSalva    := cFilAnt
cFilAnt       := SZW->ZW_FILIAL
_cArmazemTerc := SuperGetMV("IT_ARMAZTE",.T.,"36;")
_nPesoParam   := SuperGetMV("IT_PESOBRL",.T.,4000)
_cProexc      := SuperGetMV("IT_ZWEXC",.T.,"00010225901;00010145901")
_cArmzRevenda := SuperGetMV("IT_ARMREV",.T.,"22")
_cArmzLocal   := SuperGetMV("IT_ARMNRV",.T.,"20")
cFilAnt       := _cFilSalva

Begin Sequence

	_aRecnoSZW := {}

	_lHaArmz36 := .F.

	_lSoArmaz36 := .T.  // Todos os itens são do armazem 36.

	_nPesoSZW  := 0
	_nSomaPeso := 0 // Soma dos pesos da tabela SZW.

	lCidAtendeOPL:=.F.

	_cProds:=""
	nConta:=0

	SZW->( DBSetOrder(1) )
	SZW->( DBSeek( _cCodFil + _cIdPedido ) )

	SA1->(DBSetOrder(1))
	SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))
	SA2->(DBSetOrder(1))

	nSA2PesoRef :=0
	nSA2PesoSeco:=0
	nSB1SomaRef :=0
	nSB1SomaSeco:=0
	_cLOG:="FILIAL LOGADA: cFilAnt = "+cFilAnt+CRLF
	_cLOG:="PED. PORTAL: _cIdPedido = "+_cIdPedido+CRLF

	CC2->(DBSetOrder(1))
	CC2->(DBSeek(xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN) )
	If !Empty(CC2->CC2_I_OPCO) .And. _cfilpro $ "90/40"
		If SA2->(DBSeek(xFilial("SA2")+CC2->CC2_I_OPCO+CC2->CC2_I_OPLO))
			nSA2PesoRef  := SA2->A2_I_PMAXR
			nSA2PesoSeco := SA2->A2_I_PMAXS
			lCidAtendeOPL:=.T.

			_cLOG+="ACHOU NO SA2 CC2->CC2_I_OPCO+CC2->CC2_I_OPLO = "+CC2->CC2_I_OPCO+" "+CC2->CC2_I_OPLO+CRLF
			_cLOG+="Com nSA2PesoRef = "+CVALTOCHAR(nSA2PesoRef)+CRLF
			_cLOG+="Com nSA2PesoSeco = "+CVALTOCHAR(nSA2PesoSeco)+CRLF

		Else
			_cLOG+="NAO ACHOU SA2 CC2->CC2_I_OPCO+CC2->CC2_I_OPLO = "+CC2->CC2_I_OPCO+" "+CC2->CC2_I_OPLO+CRLF
		EndIf
	Else
		_cLOG+="NAO ACHOU CC2 xFilial(CC2)+SA1->A1_EST+SA1->A1_COD_MUN = "+xFilial("CC2")+" "+SA1->A1_EST+" "+SA1->A1_COD_MUN+CRLF
		_cLOG+="CC2->CC2_I_OPCO+CC2->CC2_I_OPLO = "+CC2->CC2_I_OPCO+" "+CC2->CC2_I_OPLO+CRLF
	EndIf

	While SZW->( !Eof() ) .And. _cCodFil + _cIdPedido == SZW->( ZW_FILIAL + ZW_IDPED )

//----------------------------------------------------------------- // JPP TESTE - Rever este trecho. Incluir aqui a nova regra.

		// Faz a somatória dos Pesos.
		_nPesoSZW := Posicione("SB1",1,xFilial("SB1")+SZW->ZW_PRODUTO,"B1_PESBRU")
		_nSomaPeso:= (_nSomaPeso + (_nPesoSZW * SZW->ZW_QTDVEN))
		_cLOG+="Produto: "+SZW->ZW_PRODUTO+" - Peso: "+CVALTOCHAR(_nPesoSZW)+CRLF
		If SB1->B1_TIPCAR == "000002" // Carga Refrigerada
			nSB1SomaRef  +=(_nPesoSZW * SZW->ZW_QTDVEN)
			_cLOG+="nSB1SomaRef += "+CVALTOCHAR(_nPesoSZW)+" * "+CVALTOCHAR(SZW->ZW_QTDVEN)+CRLF
		Else// Carga Seca
			nSB1SomaSeco +=(_nPesoSZW * SZW->ZW_QTDVEN)
			_cLOG+="nSB1SomaSeco += "+CVALTOCHAR(_nPesoSZW)+" * "+CVALTOCHAR(SZW->ZW_QTDVEN)+CRLF
		EndIf

		_cProds+=AllTrim(SZW->ZW_PRODUTO)+";"
		nConta++
		aAdd(_aRecnoSZW,SZW->(Recno()))

		If SZW->ZW_LOCAL == AllTrim(_cArmazemTerc)

			_lHaArmz36 := .T.

		Else

			_lSoArmaz36 := .F.

		EndIf

		SZW->(DBSkip())

	EndDo
	_cProds:=LEFT(_cProds,Len(_cProds)-1)
	_cLOG+="If lCidAtendeOPL = "+If(lCidAtendeOPL,"VERDADEIRO","FALSO")+CRLF
	_cLOG+=" AND nSB1SomaRef = "+CVALTOCHAR(nSB1SomaRef)+CRLF
	_cLOG+="  <= nSA2PesoRef = "+CVALTOCHAR(nSA2PesoRef)+CRLF
	_cLOG+="AND nSB1SomaSeco = "+CVALTOCHAR(nSB1SomaSeco)+CRLF
	_cLOG+=" <= nSA2PesoSeco = "+CVALTOCHAR(nSA2PesoSeco)+CRLF
	_cLOG+="lCidAtendeOPL .And. (nSB1SomaRef <= nSA2PesoRef) .And. (nSB1SomaSeco <=  nSA2PesoSeco) = "+;
		If(lCidAtendeOPL .And. (nSB1SomaRef <= nSA2PesoRef) .and.(nSB1SomaSeco <=  nSA2PesoSeco),"VERDADEIRO","FALSO")+CRLF

		If lCidAtendeOPL .And. (nSB1SomaRef <= nSA2PesoRef) .And. (nSB1SomaSeco <=  nSA2PesoSeco)

			cQry += "SELECT NVL(COUNT(DISTINCT ZGL_PRODUT),0) TOT FROM ZGL010 "+CRLF
			cQry += "  WHERE ZGL_FILIAL =  '"+_cfilpro+"' " +CRLF
			cQry += "    AND ZGL_FORNEC =  '"+CC2->CC2_I_OPCO+"' " +CRLF
			cQry += "    AND ZGL_LOJA   =  '"+CC2->CC2_I_OPLO+"' " +CRLF
			cQry += "    AND ZGL_MSBLQL <> '1' "+CRLF
			cQry += "    AND ZGL_PRODUT IN "+FormatIn(AllTrim(_cProds),";")+CRLF
			cQry += "    AND D_E_L_E_T_ = ' ' "	+CRLF

			DBUSEAREA( .T. , "TOPCONN" , TcGenQry(,, cQry ) , _cAlias , .T., .F. )

			(_cAlias)->(DBGoTop())
			If (_cAlias)->TOT <> nConta
				lCidAtendeOPL:=.F.
			EndIf
			_cLOG+="SELECT DO ZGL:  "+cQry+CRLF
			_cLOG+="RESULTADO DO SELECT ZGL: (_cAlias)->TOT = "+CVALTOCHAR((_cAlias)->TOT)+CRLF
			_cLOG+=" Qtde de itens:  nConta = "+CVALTOCHAR(nConta)+CRLF
			_cLOG+=" [If (_cAlias)->TOT <> nConta] => lCidAtendeOPL = "+If(lCidAtendeOPL,"VERDADEIRO","FALSO")+CRLF

			If lCidAtendeOPL
				For _nI := 1 To Len(_aRecnoSZW)
					SZW->(DBGoTo(_aRecnoSZW[_nI]))
					If !SZW->ZW_TIPO $ "01,08,10"
						_cLOG+="If !SZW->ZW_TIPO [ "+SZW->ZW_TIPO+" ] $ 01,08 => DEU Loop"+CRLF
						Loop
					EndIf
					_cLOG+="If SZW->ZW_TIPO [ "+SZW->ZW_TIPO+" ] <> 01 => NAO DEU Loop"+CRLF
					_cLOCBZ :=(AllTrim(Posicione("SBZ",1,_cfilpro+SZW->ZW_PRODUTO,'BZ_LOCPAD')))
					SZW->(RecLock("SZW",.F.))
					If _cfilpro = "90" .And. SZW->ZW_TIPO = "01" //IGONORA 08
						SZW->ZW_TIPO:=cTipPed:=cTp:="12"
					ElseIf _cfilpro = "40" .And. SZW->ZW_TIPO <> '10' //VALE PARA 01 E 08 E <> 10
						SZW->ZW_TIPO:=cTipPed:=cTp:="31"
					EndIf
					If _cLOCBZ == '20'
						SZW->ZW_LOCAL := "50"
					Else
						SZW->ZW_LOCAL := "52"
					EndIf
					_cLOG+="Procurou _cfilpro+SZW->ZW_PRODUTO = "+_cfilpro+" "+SZW->ZW_PRODUTO+CRLF
					_cLOG+="Buscou Posicione(SBZ,1,_cfilpro+SZW->ZW_PRODUTO,'BZ_LOCPAD') = "+_cLOCBZ+CRLF
					_cLOG+="Alterou para SZW->ZW_TIPO = "+SZW->ZW_TIPO+CRLF
					_cLOG+="Alterou para SZW->ZW_LOCAL = "+SZW->ZW_LOCAL+CRLF
					SZW->(MSUnLock())
				Next
				Break
			EndIf

		EndIf

		// Efetua a leitura dos dados da tabela SZW para determinar os armazens dos itens.

		If _cfilpro == "90"
			SZW->( DBSetOrder(1) )
			SZW->( DBSeek( _cCodFil + _cIdPedido ) )
			While SZW->( !Eof() ) .And. _cCodFil + _cIdPedido == SZW->( ZW_FILIAL + ZW_IDPED )
//--------------------// JPP TESTE - Alterar este trecho.
				If  AllTrim(SZW->ZW_PRODUTO) $ _cProexc .And. _nSomaPeso > _nPesoParam //Produto de exceção que deve voltar para o armazém 36 se não estiver  

					RecLock("SZW",.F.)
					SZW->ZW_LOCAL := '36'
					SZW->(MSUnLock())

					_lHaArmz36 := .T.

				EndIf

				SZW->(DBSkip())

			EndDo

			//Revalida flags de armazém de terceiros
			_lHaArmz36  := .F.
			_lSoArmaz36 := .T.
			For _nI := 1 To Len(_aRecnoSZW)

				SZW->(DBGoTo(_aRecnoSZW[_nI]))
				If SZW->ZW_LOCAL == '36'
					_lHaArmz36 := .T.
				Else
					_lSoArmaz36 := .F.
				EndIf

			Next

			If _lHaArmz36 .And. !_lSoArmaz36 //Diversos Armazéns
				For _nI := 1 To Len(_aRecnoSZW)
					SZW->(DBGoTo(_aRecnoSZW[_nI]))
					_cRevenda :=(AllTrim(Posicione("SBZ",1,_cfilpro+SZW->ZW_PRODUTO,'BZ_I_REVEN')))
					If SZW->ZW_LOCAL == '36'
						If _cRevenda == "S"
							SZW->(RecLock("SZW",.F.))
							SZW->ZW_LOCAL := _cArmzRevenda  //22
							SZW->(MSUnLock())
						Else
							SZW->(RecLock("SZW",.F.))
							SZW->ZW_LOCAL := _cArmzLocal  //30
							SZW->(MSUnLock())
						EndIf
					EndIf
				Next
			EndIf

			// Quando todos os itens forem armazem 36, Ignora-se as regras anteriores. Se o peso dos itens
			// For menor que o peso do parâmetro. Aplica-se a regra da estrutura.
			If _lSoArmaz36
				For _nI := 1 To Len(_aRecnoSZW)
					SZW->(DBGoTo(_aRecnoSZW[_nI]))
					If _nSomaPeso < _nPesoParam //.OR. SZW->ZW_TIPO <> "25"
						_cRevenda :=(AllTrim(Posicione("SBZ",1,_cfilpro+SZW->ZW_PRODUTO,'BZ_I_REVEN')))
						If _cRevenda == "S"
							SZW->(RecLock("SZW",.F.))
							SZW->ZW_LOCAL := "22"
							SZW->(MSUnLock())
						Else
							SZW->(RecLock("SZW",.F.))
							SZW->ZW_LOCAL := "20"
							SZW->(MSUnLock())
						EndIf
					EndIf
				Next
			EndIf

		EndIf
	End Sequence

	If !Empty(_cLOG) .And. GetMV( "IT_AO116LO" ,,.F.)
		_cFileNome:="\data\Italac\NT\LOGS\AOMS112_"+_cCodFil+"__"+AllTrim(_cIdPedido)+"__"+StrTran(TIME(),":","_")+".TXT"
		MemoWrite(_cFileNome,_cLOG)
	EndIf

Return
/*
===============================================================================================================================
Programa--------: AOMS112DI
Autor-----------: Josué Danich
Data da Criacao-: 03/05/2019
Descrição-------: Desmarca impressão
Parametros------: oproc - objeto da barra de processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112DI(oproc)

Local _nposi := TRBF->(Recno())
Private _aPed			:= {}

TRBF->( DBGoTop() )

//Imprime todos os pedidos selecionados
While TRBF->(!Eof())

	// Somente pedidos selecionados pelo usuario
	If (TRBF->OK == cmarca .And. !linverte) .Or. (TRBF->OK != cmarca .And. linverte)

		SZW->(DBSetOrder(1))
		If SZW->(DBSeek(SubStr(TRBF->FILIAL,1,2)+TRBF->NUMPED))

			aAdd(_aped,{AllTrim(SZW->ZW_FILIAL) ,AllTrim(SZW->ZW_IDPED) , AllTrim(SZW->ZW_CLIENTE) , AllTrim(SZW->ZW_LOJACLI) ,  SZW->ZW_VEND1 })

			TRBF->( RecLock( "TRBF", .F. ) )
			TRBF->IMPRIME := '2-NAO'
			TRBF->( MSUnLock() )

			aarr[aScan(aarr,{|x| x[Len(x)] == TRBF->(Recno())}),04] := '2-NAO'

			While 	SubStr(TRBF->FILIAL,1,2)+TRBF->NUMPED == SZW->ZW_FILIAL+SZW->ZW_IDPED

				SZW->( RecLock( "SZW", .F. ) )
				SZW->ZW_IMPRIME := ' '
				SZW->( MSUnLock() )

				SZW->(DBSkip())

			EndDo

		EndIf

	EndIf

	TRBF->(DBSkip())

EndDo

If Len(_aped) = 0

	//Imprime somente pedido posicionado
	TRBF->(DBGoTo(_nposi))

	SZW->(DBSetOrder(1))
	If SZW->(DBSeek(SubStr(TRBF->FILIAL,1,2)+TRBF->NUMPED))

		TRBF->( RecLock( "TRBF", .F. ) )
		TRBF->IMPRIME := '2-NAO'
		TRBF->( MSUnLock() )

		aarr[aScan(aarr,{|x| x[Len(x)] == TRBF->(Recno())}),04] := '2-NAO'


		While 	SubStr(TRBF->FILIAL,1,2)+TRBF->NUMPED == SZW->ZW_FILIAL+SZW->ZW_IDPED

			SZW->( RecLock( "SZW", .F. ) )
			SZW->ZW_IMPRIME := ' '
			SZW->( MSUnLock() )

			SZW->(DBSkip())

		EndDo

	EndIf

EndIf

//Atualiza tela
FWMsgRun(,{|| AOMS112arq(oproc)},"5 - Aguarde...","Atualizando tela...")

omark:setarray(aarr)
omark:refresh()
ProcessMessages()

//Retorna browse ao pedidos posicionado
TRBF->(DBGoTo(_nposi))

Return

/*
===============================================================================================================================
Programa--------: AOMS112ENT
Autor-----------: Josué Danich
Data da Criacao-: 10/05/2019
Descrição-------: Valida Data de entrega do pedido
Parametros------:	_lAutoref - execução de pedidos múltiplos
Retorno---------:  lRet := Informa se validou os preços do pedido 
===============================================================================================================================
*/
Static Function AOMS112ENT(_lAutoref )

Local _lOk		 := .T.
Local dDtEnt     := SZW->ZW_FECENT
Local dDtAgenMax := SZW->ZW_FECENT
Local _cTpAgenda := If(SZW->ZW_I_AGEND$"PIAMO",SZW->ZW_I_AGEND,"I")
Local _cFilCarreg := ""

Private aheader  := {{1,"C6_ITEM"},{2,"C6_PRODUTO"},{3,"C6_LOCAL"}}
Private acols    := {}

_cFilCarreg := SZW->ZW_FILIAL

If !Empty(SZW->ZW_FILPRO) .And. !(AllTrim(SZW->ZW_FILPRO)=='0')
	_cFilCarreg := SZW->ZW_FILPRO
EndIf

//Se é entrega agendada ou agendada com multa faz validação de transit time
If	AllTrim(_cTpAGenda) == 'A' .Or.  AllTrim(_cTpAGenda) == 'M'
	dDtEnt := DATE()+u_omsvldent(DATE(),SZW->ZW_CLIENTE,SZW->ZW_LOJACLI,SZW->ZW_FILIAL,SZW->ZW_IDPED,1,.F.,_cFilCarreg,SZW->ZW_TIPO,SZW->ZW_TPVENDA)

	dDtAgenMax := U_DTVAL112(dDtEnt)

	If dDtEnt == Date()

		//Falha de regra
		_cmens := "Cad. de Transit Time não encontradao ou Qtd Dias Zerado para pedido, verificar o Cad. de Transit Time x Dados do Cliente/Remessa."
		_lOk := .F.

	ElseIf SZW->ZW_FECENT < dDtEnt

		_cmens := "Data de Entrega "+DToC(SZW->ZW_FECENT)+" menor que transit time, data mínima de Entrega : " + DToC(dDtEnt)
		_lOk := .F.

	ElseIf SZW->ZW_FECENT > dDtAgenMax

		_cmens := "Data de Agendamento "+DToC(SZW->ZW_FECENT)+" maior que a Data Máxima permitida para Agendamento, data máxima: " + DToC(dDtAgenMax)
		_lOk := .F.

	EndIf

	If _lAutoref .And. !_lOk

		SA1->(DBSetOrder(1))
		SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

		aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),SZW->ZW_FILIAL,AllTrim(SZW->ZW_IDPED),SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME),_cmens})

	ElseIf !_lOk

		U_ITMsg(_cmens,"Atenção","Verifique regra de transit time para a cidade do pedido",1)

	EndIf

EndIf

Return( _lok )

/*
===============================================================================================================================
Programa--------: AOMS112K
Autor-----------: Josué Danich
Data da Criacao-: 15/05/2019
Descrição-------: Valida Data de entrega do pedido
Parametros------:	_cclirem - código do cliente selecionado
									_clojrem - codigo da loja selecionada
Retorno---------:  _lRet := Informa se validou os preços do pedido 
===============================================================================================================================
*/
Static Function AOMS112K(_cclirem,_clojrem)

Local _lRet := .T.

Begin Sequence

//Não pode escolher mesmo cliente do pedido para remessa
	If !Empty(_cclirem) .And. AllTrim(_cclirem) + AllTrim(_clojrem) == AllTrim(TRBF->CODCLI)+AllTrim(TRBF->LOJA)

		U_ITMsg("Não é permitido escolher mesmo Cliente/Remessa do pedido para remessa","Atenção",,1)
		_lRet := .F.
		Break

	EndIf

//Se escolheu cliente vazio e já está selecionada operação triangular pergunta se quer limpar operação
	If Empty(_cclirem) .And. !Empty(TRBF->CLIREM)

		If !(U_ITMsg("Eliminar operação triangular desse pedido?(" + AllTrim(TRBF->NUMPED) + ")","Atenção",,3,2,2))

			_lRet := .F.
			Break

		EndIf

	EndIf

	SA1->(DBSetOrder(1))
	If !(SA1->(DBSeek(xFilial("SA1")+AllTrim(_cclirem)+AllTrim(_clojrem))))

		U_ITMsg("Cliente/Remessa não localizado no cadastro: "+_cclirem+ "/"+_clojrem,"Atenção",,1)
		_lRet := .F.
		Break

	ElseIf SA1->A1_MSBLQL = '1'

		U_ITMsg("Cliente/Remessa bloqueado","Atenção",SA1->A1_COD + "/"+SA1->A1_LOJA + " - "+AllTrim(SA1->A1_NOME),1)
		_lRet := .F.
		Break

	EndIf


End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: aoms112B
Autor-----------: Julio de Paula Paz
Data da Criacao-: 22/01/2018
Descrição-------: Permite alterar o armazem do item de Pedido, na efetivação do Pedido de Vendas do Portal.
Parametros------: _nLin = Numero da linha do ACols.
                  _nPosLocal = Coluna do ACols que possui o código do armazem.
                  _nPosProd = Posição do código do produto no aCols.
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function aoms112B(_nLin, _nPosLocal,_nPosProd) //aoms112B(_nLin, _nPosLocal)

Local _bOk, _bCancel
Local _oDlgLocal
Local _lRet := .T.
Local _cTitulo
Local _cArmazAtu, _cArmazNovo, _cCodProduto
Local _cItem, _aItens := {"Atual (Posicionado)","Todos os Itens"}
Local _nAjusteLin := 30
Local _nI

Begin Sequence
	// Tela de Alteração do Armazem do item de Pedido de Vendas
	_cTitulo := "Alteração do Armazem do item de Pedido de Vendas"
	_bOk := {|| If(U_aoms112D(_cArmazNovo,_cCodProduto),(_lRet := .T., _oDlgLocal:End()),)}
	_bCancel := {|| _lRet := .F., _oDlgLocal:End()}

	_cArmazAtu := aCols[_nLin, _nPosLocal]

	_cArmazNovo := _cArmazAtu

	_cCodProduto := aCols[_nLin, _nPosProd]

	Define MsDialog _oDlgLocal Title _cTitulo From 9,0 To 22,55 Of oMainWnd

	@ 06+_nAjusteLin,20 Say "Item a Ser Alterado: " Of _oDlgLocal Pixel
	@ 06+_nAjusteLin,80 ComboBox _cItem Items _aItens Of _oDlgLocal Pixel Size 080,010

	@ 26+_nAjusteLin,20 Say "Armazem Atual: " Of _oDlgLocal Pixel
	@ 25+_nAjusteLin,80 Get _cArmazAtu Size 30, 10 WHEN .F. Of _oDlgLocal Pixel

	@ 46+_nAjusteLin,20 Say "Novo Armazem: " Of _oDlgLocal Pixel
	@ 45+_nAjusteLin,80 MsGet _cArmazNovo F3 "NNR" Size 30, 10 Valid(U_aoms112D(_cArmazNovo,_cCodProduto )) Of _oDlgLocal Pixel

	Activate MsDialog _oDlgLocal On Init EnchoiceBar(_oDlgLocal,_bOk,_bCancel) CENTERED

	// Altera o armazem do Acol se confirmado a alteração pele usuário.
	If _lRet
		If _cItem == "Atual (Posicionado)"
			aCols[_nLin, _nPosLocal] := _cArmazNovo
		Else
			For _nI := 1 To Len(aCols)
				aCols[_nI, _nPosLocal] := _cArmazNovo
			Next
		EndIf
	EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa--------: aoms112D
Autor-----------: Julio de Paula Paz
Data da Criacao-: 22/01/2018
Descrição-------: Permite alterar o armazem do item de Pedido, na efetivação do Pedido de Vendas do Portal. Validação.
Parametros------: _cArmazNovo  = Novo código do Armazem.
                  _cCodProduto = Código do Produto.
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function aoms112D(_cArmazNovo,_cCodProduto)

Local _lRet := .T.
Local _aOrd := SaveOrd({"SB2","NNR"})
Begin Sequence
	SB2->(DBSetOrder(1)) // B2_FILIAL+B2_COD+B2_LOCAL
	NNR->(DBSetOrder(1)) // NNR_FILIAL+NNR_CODIGO

	If Empty(_cArmazNovo)
		U_ITMsg("O novo código do armazem precisa ser informado.","Atenção.", ,1)
		lRet := .F.
		Break
	EndIf

	If ! NNR->(DBSeek(xFilial("NNR")+_cArmazNovo))
		U_ITMsg("O código de armazem informado não existe. ","Atenção.", ,1)
		lRet := .F.
		Break
	EndIf

End Sequence

RestOrd(_aOrd)

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS112I
Autor-------------: Alex Wallauer
Data da Criacao---: 06/01/2020
Descrição---------: Processamento de Importação de Pedidos do Broker via arquivo CSV
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112I()
	
Local _aParAux := {},nI
Local _aParRet := {}
Local _bOK     := {|| .T. }

MV_PAR01:=Space(200)
aAdd( _aParAux , { 1 , "Selecione arquivo .CSV:",MV_PAR01, "@!"	, "", "DIR","", 100, .T. } )

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI
// 1 - < aParametros > - Vetor com as configurações
// 2 - < cTitle >      - Título da janela
// 3 - < aRet >        - Vetor passador por referencia que contém o retorno dos parâmetros
// 4 - < bOk >         - Code block para validar o botão Ok
// 5 - < aButtons >    - Vetor com mais botões além dos botões de Ok e Cancel
// 6 - < lCentered >   - Centralizar a janela
// 7 - < nPosX >       - Se não centralizar janela coordenada X para início
// 8 - < nPosY >       - Se não centralizar janela coordenada Y para início
// 9 - < oDlgWizard >  - Utiliza o objeto da janela ativa
//10 - < cLoad >       - Nome do perfil se caso For carregar
//11 - < lCanSave >    - Salvar os dados informados nos parâmetros por perfil
//12 - < lUserSave >   - Configuração por usuário
//        aParametros,cTitle,aRet     ,bOk ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
If !ParamBox( _aParAux , "" ,@_aParRet,_bOK,        ,         ,     ,     ,          ,     ,.T.     ,.T. )//Intervalo de Datas e Filial
	Return .F.
EndIf

FWMsgRun( ,{|oProc| U_AOMS112I(oProc) },,'Iniciando o processamento...' )

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS112I
Autor-------------: Alex Wallauer
Data da Criacao---: 06/01/2020
Descrição---------: Processamento de Importação de Pedidos do Broker via arquivo CSV
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS112I(oProc)

Local _nCpo,_cTot
Local lHtml:= (GetRemoteType() == 5) //Valida se o ambiente é SmartClientHtml
Private _aPercLeiteMadro:={}

oProc:cCaption := ("Lendo dados do arquivo CSV...")
ProcessMessages()

_cArq := AllTrim(MV_PAR01)

If lHtml
	cDirDest:="\DATA\LAMBERT\"
	If CpyT2S( _cArq , cDirDest )
		_cArq:=cDirDest+SubStr(_cArq,RAt('\',_cArq) )
	Else
		U_ITMsg("Não foi possível COPIAR o arquivo informado "+_cArq+" PARA: "+cDirDest,;
			"Arquivo inválido","O arquivo informado deve ser .CSV ou verificar se o arquivo informado esta correto.",1)
		Return .F.
	EndIf
EndIf

If Upper(RIGHT(_cArq,3)) <> "CSV" .Or. FT_FUSE(_cArq) = -1
	U_ITMsg("Não foi possível abrir o arquivo informado: "+_cArq,;
		"Arquivo inválido","O arquivo informado deve ser .CSV ou verificar se o arquivo informado esta correto.",1)
	Return .F.
EndIf

_cTot:=FT_FLASTREC()-1
_cTot:=AllTrim(Str(_cTot))
_nTam:=Len(_cTot)+1

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
_cDados := FT_FREADLN()

lLambert:=.F.
lOutros:=.F.
If "COD PEDIDO;CNPJ;COD CLIENTE;ITEM;QTD UNI;QTD DA CAIXA;VALORT DO ITEM;FORMA PG;VL_UNI;QTD CX;VL UNI SEM IMPOSTO;COD REPRESENTANTE;COD TABELA;FILIAL" $ Upper(AllTrim(_cDados))
	lOutros:=.T.
Else
	FT_FUSE()
	U_ITMsg("O arquivo "+_carq+" informado para relizar a importação não tem o layout padrão.",;
		"Arquivo com formato inválido",;
		"O CSV deve ter as colunas [ COD PEDIDO;CNPJ;COD CLIENTE;ITEM;QTD UNI;QTD DA CAIXA;VALORT DO ITEM;FORMA PG;VL_UNI;QTD CX;VL UNI SEM IMPOSTO;COD REPRESENTANTE;COD TABELA;FILIAL ] e o mesmo deve ser salvo "+;
		"no Excel no formato [ CSV (separado por virgulas) ] e "+;
		"no LibreOffice Calc com Demilitador de campo Ponto e Virgula e sem delimitador de texto.",1)
	Return .F.
EndIf

FT_FSKIP()
_aDados:={}
_nCont:=_nConta:=0
_nErro:=0
_aPedErro:={}
_aItemRepetido={}
SB1->(DBSetOrder(1))
DA1->(DBSetOrder(1))
SA1->(DBSetOrder(1))
SZW->(DBSetOrder(17))//COD PEDIDO --> ZW_PEDIMPO

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO

	_nCont++
	oProc:cCaption := ("Lendo Dados do TXT: "+ StrZero(_nCont,_nTam) +" de "+ _cTot)
	ProcessMessages()

	_cDados := FT_FREADLN()
	_cDados := StrTran(_cDados,'"','')//Tem que ter ate 6 colunas
	_cDados := StrTran(_cDados,'.','') //Campos com PONTO por Branco
	_cDados := StrTran(_cDados,',','.')//Campos com decimais "virugla por ponto"

	If Empty(_cDados)
		FT_FSKIP()
		Loop
	EndIf
	//Verifica se é final de arquivo
	If AllTrim(_cDados) = ';;;;;'
		FT_FSKIP()
		Loop
	EndIf
	_nConta++

	_aLinhas:= StrTokArr2(_cDados,";",.T.)//Tem que ter ate 6 colunas
	_aItens:={}

	If Len(_aLinhas) < 11
		_aLinhas:=U_ITTXTARRAY(_cDados,"",11,11)
	EndIf

	aAdd(_aItens,.T.)                                   //01
	aAdd(_aItens,If(Len(_aLinhas) > 00,_aLinhas[01],""))//02
	aAdd(_aItens,If(Len(_aLinhas) > 01,_aLinhas[02],""))//03
	aAdd(_aItens,If(Len(_aLinhas) > 02,_aLinhas[03],""))//04
	aAdd(_aItens,If(Len(_aLinhas) > 03,_aLinhas[04],""))//05
	aAdd(_aItens,If(Len(_aLinhas) > 04,_aLinhas[05],""))//06
	aAdd(_aItens,If(Len(_aLinhas) > 05,_aLinhas[06],""))//07
	aAdd(_aItens,If(Len(_aLinhas) > 06,_aLinhas[07],""))//08
	aAdd(_aItens,If(Len(_aLinhas) > 07,_aLinhas[08],""))//09
	aAdd(_aItens,If(Len(_aLinhas) > 08,_aLinhas[09],""))//10
	aAdd(_aItens,If(Len(_aLinhas) > 09,_aLinhas[10],""))//11
	aAdd(_aItens,If(Len(_aLinhas) > 10,_aLinhas[11],""))//12
	//Outros
	aAdd(_aItens,If(Len(_aLinhas) > 11,_aLinhas[12],""))//13 COD REPRESENTANTE
	aAdd(_aItens,If(Len(_aLinhas) > 12,_aLinhas[13],""))//14 COD TABELA
	aAdd(_aItens,If(Len(_aLinhas) > 13,_aLinhas[14],""))//15 FILIAL

	aAdd(_aItens,If(Len(_aLinhas) > 14,_aLinhas[15],""))//16 PEDIDO CLIENTE
	aAdd(_aItens,If(Len(_aLinhas) > 15,_aLinhas[16],""))//17 OBS PARA NFE

	aAdd(_aItens,If(Len(_aLinhas) > 16,_aLinhas[17],""))//18 TIPO DE ENTREGA
	aAdd(_aItens,If(Len(_aLinhas) > 17,_aLinhas[18],""))//19 DATA DE ENTREGA

	aAdd(_aItens,""                                    )//20 Erro -> Len(_aItens)

	_lAchouSA3:=.F.
	cCODVEND:=""
	If Empty(_aItens[13])  //13 COD REPRESENTANTE
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ COD REPRESENTANTE não INFORMADO ] "+CRLF
	EndIf

	//QUANDO É Lambert posiciona no SA3 para pegar a tabela de preço
	If !Empty(_aItens[13])  //13 COD REPRESENTANTE
		cCODVEND:=StrZero(Val(AllTrim(_aItens[13])),6)
		SA3->(DBSetOrder(1))
		If SA3->(DBSeek(xFilial("SA3")+AllTrim(cCODVEND)))
			_aItens[13]:=SA3->A3_COD+" - "+AllTrim(SA3->A3_NOME)+" ["+_aItens[13]+"]"//NÃO MEXER NA ORDEM USO PARA DAR SEEK PARA FRENTE
			_lAchouSA3:=.T.
		Else
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ COD REPRESENTANTE não Encontrado ] "+CRLF
		EndIf
	EndIf

	If Empty(_aItens[15])//15 FILIAL
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ FILIAL não INFORMADA ] "+CRLF
	Else
		SM0->(DBSetOrder(1))
		If !SM0->(DBSeek(cEmpAnt + _aItens[15]))
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ FILIAL invalida ] "+CRLF
		EndIf
	EndIf

	SZW->(DBSetOrder(17))// ZW_FILIAL+ZW_PEDIMPO
	If Empty(_aItens[2])
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ COD PEDIDO não INFORMADO ] "+CRLF
	ElseIf !Empty(cCODVEND) .And. !Empty(_aItens[15]) .And. SZW->(DBSeek(_aItens[15]+U_ITkey(_aItens[2],"ZW_PEDIMPO")+cCODVEND))//ZW_PEDIMPO
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ Cod. Vend.+Cod. Ped. Imp. (PEDIMPO): (	"+cCODVEND+"+"+AllTrim(_aItens[2])+") já importado no Pedido Portal (IDPED): ("+_aItens[15]+" "+AllTrim(SZW->ZW_IDPED)+") ] "+CRLF
	EndIf

	_lAchouSA1:=.F.
	If Empty(_aItens[3])
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ CNPJ não informado ] "+CRLF
	Else
		cCPFCNPJ  :=StrZero(Val(AllTrim(_aItens[3])),14)
		SA1->(DBSetOrder(3))
		If SA1->(DBSeek(xFilial("SA1")+AllTrim(cCPFCNPJ)))
			cCPFCNPJ  :=SubStr(cCPFCNPJ,1,2)+"."+SubStr(cCPFCNPJ,3,3)+"."+SubStr(cCPFCNPJ,6,3)+"/"+SubStr(cCPFCNPJ,9,4)+"-"+ SubStr(cCPFCNPJ,13,2)
			_aItens[3]:=SA1->A1_COD+"-"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" ["+cCPFCNPJ+"]"//NÃO MEXER NA ORDEM USO PARA DAR SEEK PARA FRENTE
			_lAchouSA1:=.T.
		Else
			cCPFCNPJ  :=SubStr(cCPFCNPJ,1,2)+"."+SubStr(cCPFCNPJ,3,3)+"."+SubStr(cCPFCNPJ,6,3)+"/"+SubStr(cCPFCNPJ,9,4)+"-"+ SubStr(cCPFCNPJ,13,2)
			_aItens[3]:="["+cCPFCNPJ+"]"
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ CNPJ não Encontrado ] "+CRLF
		EndIf
	EndIf

	If _lAchouSA1 .And. _lAchouSA3
		If SA1->A1_VEND <> SA3->A3_COD .And. SA1->A1_I_VEND2 <> SA3->A3_COD
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ Cliente/Remessa não pertence ao Vendedor ("+SA3->A3_COD+") / Vendedor do Cliente ("+SA1->A1_VEND+") ] "+CRLF
		EndIf
	EndIf

	If Empty(_aItens[14])//14 COD TABELA
		If _lAchouSA1 .And. !Empty(SA1->A1_TABELA)
			_aItens[14]:=LEFT(SA1->A1_TABELA,Len(DA1->DA1_CODTAB))
		ElseIf _lAchouSA3
			_aItens[14]:=LEFT(SA3->A3_I_TABPR,Len(DA1->DA1_CODTAB))
		EndIf
	EndIf
	If Empty(_aItens[14])//14 COD TABELA
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ COD TABELA não informado ] "+CRLF
	EndIf
	cTabPreco:=_aItens[14]

	If !Empty(cTabPreco) .And. !DA1->(DBSeek(xFilial("DA1")+cTabPreco))
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ COD TABELA PREÇO não encontrado: " + cTabPreco + "] "+CRLF
	EndIf

	If Empty(_aItens[5])
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ ITEM não informada ] "+CRLF
	Else
		_aItens[5]:=StrZero(Val(AllTrim(_aItens[5])),11)

		If aScan(_aItemRepetido,_aItens[2]+_aItens[5]) = 0
			aAdd(_aItemRepetido,_aItens[2]+_aItens[5])
		Else
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ ITEM REPETIDO ("+AllTrim(_aItens[5])+") ] "
		EndIf

		_aItens[12]:=StrTran(Upper(_aItens[12]),"R$","")

		If Val(_aItens[12]) <=  0   // Preço Unitário estive zerado, buscar o Preço Item com Impostos
			_aItens[12] := _aItens[10]  //Vlr com Impostos
		EndIf

		If !SB1->(DBSeek(xFilial()+_aItens[5]))
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ ITEM não encontrado no Protheus ] "+CRLF
		Else
			If !DA1->(DBSeek(xFilial("DA1")+cTabPreco+_aItens[5]))
				_aItens[1]:=.F.
				_aItens[Len(_aItens)]+="[ ITEM não encontrado na Tabela de Preço: " + cTabPreco +"] "+CRLF

			ElseIf Round(Val(_aItens[12]),2)  > DA1->DA1_PRCMAX
				_aItens[1]:=.F.
				_aItens[Len(_aItens)]+="[ Preço acima do máximo: " + AllTrim(transform(DA1->DA1_PRCMAX,"@E 999,999,999.99"))+" da Tabela de Preço: " + cTabPreco +"] "+CRLF

			ElseIf Round(Val(_aItens[12]),2) < DA1->DA1_I_PMF3
				_aItens[1]:=.F.
				_aItens[Len(_aItens)]+="[ Preço abaixo do mínimo da Faixa 3: " + AllTrim(transform(DA1->DA1_I_PMF3,"@E 999,999,999.99"))+" da Tabela de Preço: " + cTabPreco +"] "+CRLF

			EndIf

			cArm:= Posicione("SBZ",1,_aItens[15]+_aItens[5],"BZ_LOCPAD")

			If SA3->A3_I_VBROK == 'B'
				If cArm = "20"
					cArm:= "50"
				Else
					cArm:= "52"
				EndIf
			EndIf

			_aItens[5]:=_aItens[5]+" [ "+cArm+" ] [ "+AllTrim(SB1->B1_DESC)+" ]"
		EndIf
	EndIf

	If Val(_aItens[6]) <= 0
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ QTD UNI invalida ] "+CRLF
	EndIf
	If Val(_aItens[7]) <= 0
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ QTD DA CAIXA invalida ] "+CRLF
	EndIf
	If Empty(_aItens[9])
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ FORMA PG nao informada ] "+CRLF
	Else
		_cE4_I_PRZMD:="  "
		If Len(AllTrim(_aItens[09])) < 3
			_aItens[09]:=StrZero(Val(_aItens[09]),Len(SE4->E4_CODIGO))
		EndIf
		_cCond:=AllTrim(Posicione("SE4",1,xFilial("SE4") +_aItens[09] ,"E4_DESCRI"))
		_aItens[09]:=_aItens[09]+" - "+_cCond
		_cE4_I_PRZMD:=SE4->E4_I_PRZMD

		If Empty(_cCond)
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[FORMA PG nao encontrada] "+CRLF
		ElseIf SE4->E4_I_PRZMD = 1
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[Prazo de pagamento a vista antecipado não permitido] "+CRLF
		ElseIf _lAchouSA1 .And. SE4->(DBSeek(xFilial("SE4")+SA1->A1_COND)) .And. _cE4_I_PRZMD > SE4->E4_I_PRZMD
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[Prazo medio do Pedido: "+Str(_cE4_I_PRZMD,3)+", maior que o do Cliente/Remessa: "+Str(SE4->E4_I_PRZMD,3)+"] "+CRLF
		EndIf
	EndIf

	If Val(_aItens[11]) <= 0
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[QTD CX invalida] "
	EndIf
	If (_aItens[17]) $ "IMEDIATA/AGENDADO"
		_aItens[1]:=.F.
		_aItens[Len(_aItens)]+="[ TIPO DE ENTREGA invalida ] "+CRLF
	EndIf

	If _aItens[1] = .F.
		aAdd(_aPedErro,_aItens[2])
		_nErro++
	EndIf
	aAdd(_aDados,_aItens)

	FT_FSKIP()

EndDo

FT_FUSE()

SZW->(DBSetOrder(1))

If Len(_aDados) > 0
	_aPercLeiteMadro:={}
	For _nCpo := 1 TO Len(_aDados)
		If _aDados[_nCpo,1] .And. aScan(_aPedErro,_aDados[_nCpo,2]) <> 0//Se achou
			_aDados[_nCpo,1]:=.F.//Se um der errado não vai integra o pedido todo
			_aDados[_nCpo,Len(_aDados[1])]:="[Pedido com 1 ou mais itens com erro] "
		EndIf

		If (_nPos:=aScan(_aPercLeiteMadro, {|P| P[1] == _aDados[_nCpo,2] })) = 0
			aAdd( _aPercLeiteMadro , { _aDados[_nCpo,2] , 0 , 0 , 0 } )
			_nPos:=Len(_aPercLeiteMadro)
		EndIf
		If _nPos <> 0

			cProd:=_aDados[_nCpo,5]
			nQtde:=Val(_aDados[_nCpo,06])
			SB1->(DBSeek(xFilial()+LEFT(cProd,11)))
			If SB1->B1_I_TIPLT = "M"
				_aPercLeiteMadro[_nPos,2]+=nQtde
			ElseIf SB1->B1_I_TIPLT = "I"
				_aPercLeiteMadro[_nPos,3]+=nQtde
			EndIf

		EndIf

	Next
	_aListaPerc:={}
	_cPict:=PesqPict("SZW","ZW_I_LMAGR")
	_cPictQ:=PesqPict("SZW","ZW_QTDVEN")
	For _nCpo := 1 TO Len(_aPercLeiteMadro)
		If _aPercLeiteMadro[_nCpo,2] <> 0
			_aPercLeiteMadro[_nCpo,4]:=((_aPercLeiteMadro[_nCpo,2] / (_aPercLeiteMadro[_nCpo,2]+_aPercLeiteMadro[_nCpo,3]))*100)
			aAdd( _aListaPerc , { "A"                                        ,_aPercLeiteMadro[_nCpo,1] , TRANSFORM(_aPercLeiteMadro[_nCpo,2],_cPictQ), TRANSFORM(_aPercLeiteMadro[_nCpo,3],_cPictQ) , TRANSFORM(_aPercLeiteMadro[_nCpo,4],_cPict) } )
		Else
			aAdd( _aListaPerc , { If(_aPercLeiteMadro[_nCpo,3] <> 0,"B","C") ,_aPercLeiteMadro[_nCpo,1] , TRANSFORM(_aPercLeiteMadro[_nCpo,2],_cPictQ), TRANSFORM(_aPercLeiteMadro[_nCpo,3],_cPictQ) , TRANSFORM(_aPercLeiteMadro[_nCpo,4],_cPict) } )
		EndIf
	Next
	aSort(_aListaPerc,,,{ |x,y| x[1]+x[2] < y[1]+y[2]})

	//Monta _aCab
	_aCab:={}
	_aSize:={}
	aAdd(_aCab,"")//01
	aAdd(_aSize,05)
	aAdd(_aCab,"Pedido Broker")//02
	aAdd(_aSize,40)
	aAdd(_aCab,"CNPJ")//03
	aAdd(_aSize,170)
	aAdd(_aCab,"CLIENTE")//04
	aAdd(_aSize,35)
	aAdd(_aCab,"CODIGO [ ARMAZEM ][ DESCRICAO DO PRODUTO ]")//05
	aAdd(_aSize,200)
	aAdd(_aCab,"QTD UNI")//06
	aAdd(_aSize,40)
	aAdd(_aCab,"QTD DA CAIXA")//07
	aAdd(_aSize,45)
	aAdd(_aCab,"VALORT DO ITEM")//08
	aAdd(_aSize,50)
	aAdd(_aCab,"FORMA PG")//09
	aAdd(_aSize,100)
	aAdd(_aCab,"VL_UNI")//10
	aAdd(_aSize,50)
	aAdd(_aCab,"QTD CX")//11
	aAdd(_aSize,40)
	aAdd(_aCab,"VL UNI SEM IMPOSTO")//12
	aAdd(_aSize,50)
	aAdd(_aCab,"COD REPRESENTANTE")//13
	aAdd(_aSize,150)
	aAdd(_aCab,"COD TABELA")//14
	aAdd(_aSize,45)
	aAdd(_aCab,"FILIAL")//15
	aAdd(_aSize,20)

	aAdd(_aCab,"PEDIDOC CLIENTE")//16
	aAdd(_aSize,20)
	aAdd(_aCab,"OBS PARA NFE")//17
	aAdd(_aSize,150)

	aAdd(_aCab,"TIPO DE ENTREGA")//18
	aAdd(_aSize,20)
	aAdd(_aCab,"DT ENTREGA ")//19
	aAdd(_aSize,20)


	aAdd(_aCab,"Resultado")//19
	aAdd(_aSize,500)

	_cTitAux:="Dados do Arquivo "+_cArq
	_cMsgTop:="Importação, Registros Lidos: "+AllTrim(TRANSFORM(_nConta,"@E 999,999,999"))+", Com Erros: "+AllTrim(TRANSFORM(_nErro,"@E 999,999,999"))
	While .T.

		aSort( _aDados ,,, {|X, Y| X[2] < Y[2] } )

		nPosResu:=Len(_aDados[1])//Posiçao dos Resultado"
		_aButtons:={}
		aAdd(_aButtons,{"BUDGET",{|| AVISO("RESULTADO",oLbxAux:aArray[oLbxAux:nAt][nPosResu],{"Fechar"},3)  },"", "Visualizar Resultado" })
		If Len(_aPercLeiteMadro) > 0
			aAdd( _aButtons , { "" , {|| AOM112Magro(_aListaPerc) } , "" , "Visualisar % Leite Magro"  } )
		EndIf

		//     ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _aButtons )
		lOK:=U_ITLISTBOX(_cTitAux, _aCab    , _aDados   , .T.      , 4      ,_cMsgTop  ,          , _aSize  ,         ,     ,        , _aButtons)

		If lOK .And. U_ITMsg("Confirma importação dos registros válidos",'Atenção!',,3,2,3,,"CONFIRMA","Voltar")

			AOMS112M(oProc)//GRAVA OS DADOS DO CSV
			Exit
		ElseIf !lOK .And. U_ITMsg("Confirma SAIR ?",'Atenção!',"Todos os registros de válidações serão perdidos",3,2,3,,"CONFIRMA","Voltar")
			Exit
		EndIf

	EndDo
Else
	U_ITMsg("Nenhum registro válido",'Atenção!',"Dados do Arquivo "+_cArq,1)
EndIf

If lHtml
	FERASE(_cArq)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS112M
Autor-------------: Alex Wallauer
Data da Criacao---: 06/01/2020
Descrição---------: Processamento de Importação de DADOS DO Sistema Blokers/Italac
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112M(oProc)

Local _nCpo
Local _nCont     := 0
Local _cTot      := AllTrim(Str(Len(_aDados)))
Local _cLocal    := ""
Local _cMesoReg  := ""
Local _cMicroReg := ""
Local _cCodMunic := ""
Local _cEstado   := ""
Local _lBusca_2  := .F.
Local _lAchou    := .F.

_nTam:=Len(_cTot)

_aDados2:={}

nPosResu:=Len(_aDados[1])//Posiçao do Resultado

SB1->(DBSetOrder(1))
DA1->(DBSetOrder(1))
SA1->(DBSetOrder(1))
SZW->(DBSetOrder(1))
SA3->(DBSetOrder(1))

_nCpo:=1
While _nCpo <= Len(_aDados)

	_cSalvaPed:=_aDados[_nCpo,2]//PEDIDO

	If !SA3->(DBSeek(xFilial("SA3") + LEFT(_aDados[_nCpo,13],Len(SA3->A3_COD))  ))
		_nCpo++
		Loop
	EndIf

	BEGIN TRANSACTION


		cVend:=LEFT(_aDados[_nCpo,13],Len(SA3->A3_COD))//"001583"
		_cCodSZW:=GeraZWIDPED(cVend)

		_nItem:=0

		While _nCpo <= Len(_aDados) .And. _cSalvaPed == _aDados[_nCpo,2]

			_nCont++
			oProc:cCaption := ("Processando Dados: "+ StrZero(_nCont,_nTam) +" de "+ _cTot)
			ProcessMessages()

			If _aDados[_nCpo,1] //.AND. !Empty(_cRet)
				//CAPA
				SZW->(RecLock("SZW",.T.))
				SZW->ZW_FILIAL := _aDados[_nCpo,15]
				SZW->ZW_CODEMP := "010"
				SZW->ZW_IDPED  := _cCodSZW//SubStr(_aDados[_nCpo,13],3,4)+"-"+_aDados[_nCpo,2]//_cRet//"1583-"
				SZW->ZW_EMISSAO:= Date()
				SZW->ZW_TIMEEMI:= "0"
				SZW->ZW_IDUSER := cVend//LEFT(_aDados[_nCpo,13],Len(SA3->A3_COD))//"001583"
				SZW->ZW_VEND1  := cVend//LEFT(_aDados[_nCpo,13],Len(SA3->A3_COD))//"001583"
				SZW->ZW_STATUS := "A"
				SZW->ZW_NIVELWF := " "
				SZW->ZW_ENVWF   := " "
				SZW->ZW_IMPRIME := '1'

				SA1->(DBSeek(xFilial()+LEFT(_aDados[_nCpo,3],Len(SA1->A1_COD))+SubStr(_aDados[_nCpo,3],Len(SA1->A1_COD)+2,Len(SA1->A1_LOJA)) ))

				SZW->ZW_CLIENTE:= SA1->A1_COD
				SZW->ZW_LOJACLI:= SA1->A1_LOJA
				SZW->ZW_CLIENT := SZW->ZW_CLIENTE
				SZW->ZW_LOJAENT:= SZW->ZW_LOJACLI
				SZW->ZW_TABELA := _aDados[_nCpo,14]//SA1->A1_TABELA

				If Empty(AllTrim(_aDados[_nCpo,16]))
					SZW->ZW_PEDCLI := "NT"
				Else
					SZW->ZW_PEDCLI := _aDados[_nCpo,16]//Pedido do Cliente
				EndIf

				SZW->ZW_MENNOTA := _aDados[_nCpo,17]// Mensagem para Nfe

				SZW->ZW_CONDPAG:= LEFT(_aDados[_nCpo,09], Len(SE4->E4_CODIGO) )//BuscaCond(_aDados[_nCpo,09])

				SZW->ZW_TPFRETE:= "C"
				SZW->ZW_TIPOCLI:= SA1->A1_TIPO//"R"
				SZW->ZW_TIPCAR := "2"//"1 - Paletizada" , "2 - Batida"

				SZW->ZW_PEDIMPO := _aDados[_nCpo,2]
				SZW->ZW_I_PEDDW := _aDados[_nCpo,2]

				If (_nPos:=aScan(_aPercLeiteMadro, {|P| P[1] == _aDados[_nCpo,2] })) <> 0
					SZW->ZW_I_LMAGR:=_aPercLeiteMadro[_nPos,4]
				EndIf
				//ITENS
				_nItem++
				SZW->ZW_ITEM   := AllTrim(Str( _nItem , Len(SZW->ZW_ITEM) ))
				SZW->ZW_PRODUTO:=LEFT(_aDados[_nCpo,5],11)
				SB1->(DBSeek(xFilial()+SZW->ZW_PRODUTO))
				SZW->ZW_UM     := SB1->B1_UM//"UN"

				DA1->(DBSeek(xFilial("DA1")+SZW->ZW_TABELA+SZW->ZW_PRODUTO))

				SZW->ZW_QTDVEN := Val(_aDados[_nCpo,06])
				SZW->ZW_PRCVEN := Round(Val(_aDados[_nCpo,12]),2)

				SZW->ZW_OBSCOM := "Pedido Importado TXT: "+_aDados[_nCpo,2]

				SZW->ZW_HORAINC:= Time()
				SZW->ZW_2UM    := SB1->B1_SEGUM//"CX"
				SZW->ZW_I_PRMP := DA1->DA1_I_PMF3//DA1
				SZW->ZW_I_PRNET:= SZW->ZW_PRCVEN
				SZW->ZW_PRUNIT := DA1->DA1_I_PMF3//DA1

				SZW->ZW_TPVENDA:= 'V'
				cArm:= Posicione("SBZ",1,SZW->ZW_FILIAL+SZW->ZW_PRODUTO,"BZ_LOCPAD")

				// Operação e Local
				// Para Broker Operação 12 e Local 50/52
				// Para Direto Fabrica Operação 01 e Local 20/22
				//
				// Broker quando A3_I_VBROK = B

				If SA3->A3_I_VBROK == 'B'

					SZW->ZW_TIPO   := "12" // SC5->C5_I_OPER

					If cArm = "20"
						SZW->ZW_LOCAL  := "50"
					Else
						SZW->ZW_LOCAL  := "52"
					EndIf

				Else

					SZW->ZW_TIPO   := "01" // SC5->C5_I_OPER
					SZW->ZW_LOCAL  := cArm

				EndIf

				If SB1->B1_CONV > 0
					If SB1->B1_TIPCONV = 'D'
						SZW->ZW_SEGQTD:=(SZW->ZW_QTDVEN/SB1->B1_CONV)
					Else
						SZW->ZW_SEGQTD:=(SZW->ZW_QTDVEN*SB1->B1_CONV)
					EndIf
				Else
					SZW->ZW_SEGQTD:=Val(_aDados[_nCpo,11])
				EndIf

				_cfilft    := SZW->ZW_FILIAL
				_cLocal    := cArm
				_cMesoReg  := Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MESO")
				_cMicroReg := Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MICR")
				_cCodMunic := SA1->A1_COD_MUN
				_cEstado   := SA1->A1_EST
				_lBusca_2  := .F.
				_lAchou    := .F.

				If Empty(AllTrim(_aDados[_nCpo,18]))
					SZW->ZW_I_AGEND := "I"
				Else
					If _aDados[_nCpo,18] == 'IMEDIATO'
						SZW->ZW_I_AGEND := "I"
					ElseIf _aDados[_nCpo,18] == 'AGENDADO'
						SZW->ZW_I_AGEND := "A"
					Else
						SZW->ZW_I_AGEND := "I"
					EndIf
					SZW->ZW_I_AGEND  := _aDados[_nCpo,18]//Tipo de Entrega
				EndIf

			If SZW->ZW_I_AGEND <> "A"
				If !Empty(_cLocal)

					ZG5->(DBSetOrder(3))
					If ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg+_cMicroReg+_cCodMunic))
						_lAchou   := .T.
						_lBusca_2 := .F.
					ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg+_cMicroReg))
						_lAchou   := .T.
						_lBusca_2 := .F.
					ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg))
						_lAchou   := .T.
						_lBusca_2 := .F.
					ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado))
						_lAchou   := .T.
						_lBusca_2 := .F.
					Else
						_lBusca_2 := .T.
					EndIf

				Else

					_lBusca_2 := .T.

				EndIf

				If _lBusca_2

					ZG5->(DBSetOrder(2))
					If ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg+_cMicroReg+_cCodMunic))
						_lAchou := .T.
					ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg+_cMicroReg))
						_lAchou := .T.
					ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg))
						_lAchou := .T.
					ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado))
						_lAchou := .T.
					Else
						_lAchou := .F.
					EndIf

				EndIf

				If _lAchou
					SZW->ZW_FECENT := Date() + IIf(ZG5->ZG5_FRDIAS >0,ZG5->ZG5_FRDIAS,ZG5->ZG5_DIAS) + 1
				Else
					SZW->ZW_FECENT := (Date() + 1)
				EndIf
			Else
				SZW->ZW_FECENT := CTOD(AllTrim(_aDados[_nCpo,19]))
			EndIf
				
			SZW->(MSUnLock())

				_aDados[_nCpo,5]:=AllTrim(SZW->ZW_PRODUTO)+" [ "+SZW->ZW_LOCAL+" ] [ "+AllTrim(SB1->B1_DESC)+" ]"
				_aDados[_nCpo,nPosResu]:="Codigo Pedido Gerado: "+SZW->ZW_IDPED

				aAdd(_aDados2,_aDados[_nCpo])


			EndIf

			_nCpo++

		EndDo

	END TRANSACTION

EndDo

If Len(_aDados2) = 0

	U_ITMsg("NÃO TEM registros para processar. Verifique os erros ocorridos na coluna Resultado",;
		"TODOS AS LINHAS ESTÃO VERMELHAS",;
		"Clique no CANCELAR OU ESC para sair da tela, quando todos as linhas estiverem VERMELHA",1)

	Return .F.
Else 

EndIf
_cMsgTop:="Importação, Registros Importados: "+AllTrim(TRANSFORM(Len(_aDados2),"@E 999,999,999"))

U_ITLISTBOX(_cTitAux, _aCab    , _aDados2   , .T.      , 4      ,_cMsgTop  ,          , _aSize)

If Type("aarr") = "A"
	AOMS112C(1)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: GeraZWIDPED()
Autor-------------: Alex Wallauer
Data da Criacao---: 06/01/2020
Descrição---------: Gera oproximo ZW_IDPED
Parametros--------: _cCodVen: Codigo com somente numeros
Retorno-----------: _cRet: proximo codigo
===============================================================================================================================
*/
Static Function GeraZWIDPED(_cCodVen)

Local _cAlias:= GetNextAlias()
Local _cQuery:= "SELECT  NVL(MAX(LPAD(TRIM(SubStr(ZW_IDPED,6,10)),10,'0')),'0') AS CODIGO FROM "+ RetSqlName('SZW') +" SZW WHERE ZW_VEND1 = '"+_cCodVen+"' "

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T., .F. )

(_cAlias)->( DBGoTop() )
If (_cAlias)->(!Eof()) .And. Val((_cAlias)->CODIGO) > 0
	_cRet := AllTrim(Str(Val((_cAlias)->CODIGO )+1 ) )
	_cRet := AllTrim(Str(Val(_cCodVen)))+"-"+_cRet
Else
	_cRet := AllTrim(Str(Val(_cCodVen)))+"-000001"
EndIf

If Empty(_cRet)//Para garantir não devolver branco
	_cRet := AllTrim(Str(Val(_cCodVen)))+"-000001"
EndIf

DBSelectArea(_cAlias)
DBCloseArea()
DBSelectArea("SZW")

Return _cRet

/*
===============================================================================================================================
Programa----------: BuscaCond()
Autor-------------: Alex Wallauer
Data da Criacao---: 06/01/2020
Descrição---------: Gera oproximo ZW_IDPED
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function BuscaCond(_cDias)

Local _cAlias:= GetNextAlias()

_cQuery:=" SELECT E4_CODIGO AS CODIGO , E4_I_PRZMD FROM "+ RetSqlName('SE4') +" SE4 WHERE "+ RetSqlCond('SE4') +" AND  E4_I_PRZMD  = "+_cDias+"  AND E4_I_PARCS = 1 AND E4_MSBLQL <> '1' "
DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T., .F. )
(_cAlias)->( DBGoTop() )
If (_cAlias)->(!Eof())
	_cRet := (_cAlias)->CODIGO
	_cE4_I_PRZMD:=(_cAlias)->E4_I_PRZMD
Else
	_cRet := ""
EndIf
DBSelectArea(_cAlias)
DBCloseArea()
DBSelectArea("SZW")

Return _cRet

/*
===============================================================================================================================
Programa----------: AOMS112PES
Autor-------------: Jerry
Data da Criacao---: 01/03/2020
Descrição---------: Funcao que calcula o Peso Bruto do Pedido para tratar se é Carga Fechada ou Fracionada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112PES(_cFilAux,_cNumPed)

Local _aArea := FWGetArea()
Local _nPesoSZW := 0
Local _nSomaPeso := 0

//Calcula o Peso Bruto do Pedido
DBSelectArea("SZW")
SZW->( DBSetOrder(1) )

If SZW->( DBSeek( _cFilAux + _cNumPed ) )

	While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == _cFilAux + _cNumPed

		// Faz a somatória dos Pesos.
		_nPesoSZW := Posicione("SB1",1,xFilial("SB1")+SZW->ZW_PRODUTO,"B1_PESBRU")

		_nSomaPeso += (_nPesoSZW * SZW->ZW_QTDVEN)

		SZW->(DBSkip())
	EndDo

EndIf

FWRestArea( _aArea)

Return _nSomaPeso

/*
===============================================================================================================================
Programa----------: REENVAPR
Autor-------------: Jonathan Torioni
Data da Criacao---: 14/05/2020
Descrição---------: Função de exibição do processo de aprovação de preço
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REENVAPR()

Local _nU		:= 0
Local _cFilLoc	:= ""
Local _cIdpedL	:= ""
Local _cCoord	:= ""
Local _cCoordWF := ""
Local _nQtdEnv  := 0

If Len(aarr) = 0
	U_ITMsg("Não há registros para reenviar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
	Return .F.
EndIf

SZW->(DBSelectArea("SZW"))
SZW->(DBSetOrder(1))

For _nU := 1 TO Len(aArr)

	If AllTrim(aArr[_nU][1]) != "" .And. ( AllTrim(aArr[_nU][29]) == "BR_AMARELO" .Or. AllTrim(aArr[_nU][29]) == "BR_VERDE_ESCURO" .Or. AllTrim(aArr[_nU][29]) == "BR_PRETO" )
		_cFilLoc := LEFT(aArr[_nU][A112MAP("Filial Faturamento")], 2) 	//filial
		_cIdpedL := aArr[_nU][A112MAP("Id Pedido")] 			//IDPED

		SZW->(DBSetOrder(1))
		If SZW->(DBSeek(_cFilLoc+_cIdpedL))

			_nQtdEnv++

			_cCoord     := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")
			_cCoordWF   := Posicione("SA3",1,xFilial("SA3")+_cCoord,"A3_I_WF")

			If !(SZW->ZW_BLOPRC $ 'L/R' )

				While SZW->ZW_FILIAL == _cFilLoc .And. AllTrim(SZW->ZW_IDPED) == _cIdpedL

					RecLock("SZW",.F.)

					SZW->ZW_I_HTML  := ' '
					SZW->ZW_MOTLP   := ' '
					SZW->ZW_HLIBP   := ' '
					SZW->ZW_DLIBP   := SToD("")
					SZW->ZW_ULIBP   := ' '
					SZW->ZW_MOTLP   := ' '
					SZW->ZW_BLOPRC  := ' '
					SZW->ZW_DATAAPR := SToD("")
					SZW->ZW_HORAAPR := ' '
					SZW->ZW_MLIBPRC := ' '
					SZW->ZW_OBSAVAC := 'REENVIADO WF POR ' + UsrFullName(__cUserId)
					SZW->ZW_MLIBPRC := ' '
					SZW->ZW_I_DLIBG  := SToD("")
					SZW->ZW_I_HLIBG := ' '
					SZW->ZW_BLOPRC	:= ' '
					If AllTrim(SZW->ZW_I_OBS) = 'APROVADO'
						SZW->ZW_I_OBS := ' '
					EndIf
					SZW->ZW_NIVELWF := " "
					SZW->ZW_ENVWF   := " "
					SZW->ZW_IMPRIME := '1'

					If _cCoordWF == "1"  //nao necessita de aprovação via portal
						SZW->ZW_STATUS  := "A"
					Else  // _cCoordWF == "2" -- necessita de aprovação via portal
						SZW->ZW_STATUS      := 'L'
					EndIf

					SZW->(MSUnLock())

					SZW->(DBSkip())

				EndDo
			EndIf
		EndIf
	EndIf
Next


U_ITMsg(" Total de " + AllTrim(Str(_nQtdEnv))    +  " Pedidos Enviados ","Operação Concluída!")

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS112WF
Autor-------------: Jerry
Data da Criacao---: 25/06/2020
Descrição---------: Funcao que verifica se o Pedido já passou por todas Alçada de aprovação do WF
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112WF(_cFilAux,_cNumPed)

Local _aArea    := FWGetArea()
Local _lWFOk    := .T.
Local _cCoord   := ""
Local _cCoordWF	:= ""

_cCoord     := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")
_cCoordWF   := Posicione("SA3",1,xFilial("SA3")+_cCoord,"A3_I_WF")

DBSelectArea("SZW")
SZW->( DBSetOrder(1) )

If SZW->( DBSeek( _cFilAux + _cNumPed ) )
	SA1->(DBSetOrder(1))
	
	While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == _cFilAux + _cNumPed
		// Validação Padrão do Portal
		SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

		If SZW->ZW_BLOPRC == "B"
			_lWFOk := .F.
			aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),_cFilAux,AllTrim(_cNumPed),SA1->A1_COD + "/"+SA1->A1_LOJA + " - "+AllTrim(SA1->A1_NOME),"Existe(m) item(ns) cujo(s) preço(s) informado(s) está(ão) fora da tabela de preços (ZW_BLOPRC = B'), estão aguardando WF de aprovação"})
			Exit
		Else
			_cCoord     := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")
			_cCoordWF   := Posicione("SA3",1,xFilial("SA3")+_cCoord,"A3_I_WF")
			If _cCoordWF == "2"
				If Empty(SZW->ZW_BLOPRC) .And. SZW->ZW_STATUS == "L" .And. SZW->ZW_ENVWF == "C" .And. SZW->ZW_NIVELWF == "P"
					_lWFOk := .F.
					aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),_cFilAux,AllTrim(_cNumPed),SA1->A1_COD + "/"+SA1->A1_LOJA + " - "+AllTrim(SA1->A1_NOME),"Existe(m) item(ns) cujo(s) preço(s) informado(s) está(ão) fora da tabela de preços (Empty(SZW->ZW_BLOPRC)/SZW->ZW_STATUS='L'/SZW->ZW_ENVWF='C'/SZW->ZW_NIVELWF='P), estão aguardando WF de aprovação"})
					Exit
				EndIf
			EndIf
		EndIf
		SZW->(DBSkip())
	EndDo
EndIf

FWRestArea( _aArea)

Return _lWFOk

/*
===============================================================================================================================
Programa----------: AMS112PE
Autor-------------: Jonathan Torioni
Data da Criacao---:  03/04/2020
Descrição---------: Realiza a montagem do grid com os pedidos pendentes por gerentes
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function AMS112PE()

Local _aCols 	:= {}
Local _aPeds	:= {}
Local _aGeren 	:= {}
Local _aHead	:= {}
Local _aSize	:= {}
Local _aTot		:= {}
Local _nX  		:= 0
Local _nZ		:= 0

If Len(aarr) = 0
	U_ITMsg("Não há registros para listagem.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
	Return .F.
EndIf

DBSelectArea("SA3")
SA3->(DBSetOrder(1))
For _nX := 1 TO Len(aArr)

	SA3->(DBSeek(xFilial("SA3")+SubStr(aArr[_nX][A112MAP("Vendedor")],1,6)))

	aAdd(_aPeds, {	aArr[_nX][A112MAP("Id Pedido")],;					// 1 - ZW_NUMPED
	aArr[_nX][30],;					// 2 - STATUS2
	AllTrim(aArr[_nX][29]),;		// 3 - STATUS3
	SA3->A3_GEREN})					// 4 - GERENTE

	If aScan(_aGeren, {|x| x == SA3->A3_GEREN}) == 0
		aAdd(_aGeren, SA3->A3_GEREN)
	EndIf

Next _nX


For _nX := 1 TO Len(_aGeren)

	aAdd(_aCols, {_aGeren[_nX],; 											//1 - COD GERENTE
	LoadBitmap( GetResources() , "BR_VERMELHO" ),; 	// 2
	0,;	 											//3 - QTDE LEGENDA VERMELHA
	LoadBitmap( GetResources() , "BR_PRETO" ),; 	// 4
	0,;  											//5 - QTDE LEGENDA PRETO
	LoadBitmap( GetResources() , "BR_VERDE" ),; 	// 6
	0,;  											//7 - QTDE LEGENDA VERDE
	LoadBitmap( GetResources() , "BR_AZUL" ),; 		//8
	0,;  											//9 - QTDE LEGENDA AZUL
	LoadBitmap( GetResources() , "BR_AMARELO" ),; 	// 10
	0,;  											//11 - QTDE LEGENDA AMARELA
	LoadBitmap( GetResources() , "BR_VERDE_ESCURO" ),; // 12
	0,;												//13 - QTDE LEGENDA VERDE ESCURO
	LoadBitmap( GetResources() , "BR_CANCEL" ),;	//14 - BR_CANCEL
	0,;												//15
	0})												//16 - TOTALIZADOR HORIZONTAL


	For _nZ := 1 TO Len(_aPeds)

		Do Case
		Case _aPeds[_nZ][4] == _aGeren[_nX] .And. _aPeds[_nZ][3] == "BR_VERMELHO"
			_aCols[_nX][3] ++
			_aCols[_nX][16] ++
		Case _aPeds[_nZ][4] == _aGeren[_nX] .And. _aPeds[_nZ][3] == "BR_PRETO"
			_aCols[_nX][5] ++
			_aCols[_nX][16] ++
		Case _aPeds[_nZ][4] == _aGeren[_nX] .And. _aPeds[_nZ][3] == "BR_VERDE"
			_aCols[_nX][7] ++
			_aCols[_nX][16] ++
		Case _aPeds[_nZ][4] == _aGeren[_nX] .And. _aPeds[_nZ][3] == "BR_AZUL"
			_aCols[_nX][9] ++
			_aCols[_nX][16] ++
		Case _aPeds[_nZ][4] == _aGeren[_nX] .And. _aPeds[_nZ][3] == "BR_AMARELO"
			_aCols[_nX][11] ++
			_aCols[_nX][16] ++
		Case _aPeds[_nZ][4] == _aGeren[_nX] .And. _aPeds[_nZ][3] == "BR_VERDE_ESCURO"
			_aCols[_nX][13] ++
			_aCols[_nX][16] ++
		Case _aPeds[_nZ][4] == _aGeren[_nX] .And. _aPeds[_nZ][3] == "BR_CANCEL"
			_aCols[_nX][15] ++
			_aCols[_nX][16] ++
		EndCase

	Next _nZ

Next _nX

//Monta o totalizador vertical
aAdd(_aTot, {"Total Geral",; 								//1 - COD GERENTE
LoadBitmap( GetResources() , "BR_VERMELHO" ),; 	// 2
0,;	 											//3 - QTDE LEGENDA VERMELHA
LoadBitmap( GetResources() , "BR_PRETO" ),; 	// 4
0,;  											//5 - QTDE LEGENDA PRETO
LoadBitmap( GetResources() , "ENABLE" ),; 		// 6
0,;  											//7 - QTDE LEGENDA VERDE
LoadBitmap( GetResources() , "BR_AZUL" ),; 		//8
0,;  											//9 - QTDE LEGENDA AZUL
LoadBitmap( GetResources() , "BR_AMARELO" ),; 	// 10
0,;  											//11 - QTDE LEGENDA AMARELA
LoadBitmap( GetResources() , "BR_VERDE_ESCURO" ),; // 12
0,;												//13 - QTDE LEGENDA VERDE ESCURO
LoadBitmap( GetResources() , "BR_CANCEL" ),;	//14 - BR_CANCEL
0,;												//15
0})	//16 - TOTALIZADOR HORIZONTAL

//Soma do totalizador vertical
For _nX := 1 TO Len(_aCols)
	_aTot[1][3] += _aCols[_nX][3]
	_aTot[1][5] += _aCols[_nX][5]
	_aTot[1][7] += _aCols[_nX][7]
	_aTot[1][9] += _aCols[_nX][9]
	_aTot[1][11] += _aCols[_nX][11]
	_aTot[1][13] += _aCols[_nX][13]
	_aTot[1][15] += _aCols[_nX][15]
	_aTot[1][16] += _aCols[_nX][16]
Next _nX

_aTot[1][3] := AllToChar(_aTot[1][3])
_aTot[1][5] := AllToChar(_aTot[1][5])
_aTot[1][7] := AllToChar(_aTot[1][7])
_aTot[1][9] := AllToChar(_aTot[1][9])
_aTot[1][11]:= AllToChar(_aTot[1][11])
_aTot[1][13]:= AllToChar(_aTot[1][13])
_aTot[1][15]:= AllToChar(_aTot[1][15])
_aTot[1][16]:= AllToChar(_aTot[1][16])

For _nX := 1 TO Len(_aCols)
	_aCols[_nX][1] := PadR(Posicione("SA3",1,xFilial("SA3")+_aCols[_nX][1], "A3_NOME"),40)
	_aCols[_nX][3] := AllToChar(_aCols[_nX][3])
	_aCols[_nX][5] := AllToChar(_aCols[_nX][5])
	_aCols[_nX][7] := AllToChar(_aCols[_nX][7])
	_aCols[_nX][9] := AllToChar(_aCols[_nX][9])
	_aCols[_nX][11] := AllToChar(_aCols[_nX][11])
	_aCols[_nX][13] := AllToChar(_aCols[_nX][13])
	_aCols[_nX][15] := AllToChar(_aCols[_nX][15])
	_aCols[_nX][16] := AllToChar(_aCols[_nX][16])
Next _nX

aAdd(_aCols, _aTot[1])

aAdd(_aHead , "Gerente")
aAdd(_aSize, 40)

aAdd(_aHead , " ")
aAdd(_aSize, 5)
aAdd(_aHead , "Ag. Efetivação")
aAdd(_aSize, 30)

aAdd(_aHead , " ")
aAdd(_aSize, 5)
aAdd(_aHead , "Preço Bloq.")
aAdd(_aSize, 30)

aAdd(_aHead , " ")
aAdd(_aSize, 5)
aAdd(_aHead , "Preço Lib.")
aAdd(_aSize, 30)

aAdd(_aHead , " ")
aAdd(_aSize, 5)
aAdd(_aHead , "Crédito Bloq.")
aAdd(_aSize, 30)

aAdd(_aHead , " ")
aAdd(_aSize, 5)
aAdd(_aHead , "Pend. Coord.")
aAdd(_aSize, 40)

aAdd(_aHead , " ")
aAdd(_aSize, 5)
aAdd(_aHead , "Pend. Gerente")
aAdd(_aSize, 40)

aAdd(_aHead , " ")
aAdd(_aSize, 5)
aAdd(_aHead , "Cliente/Remessa Bloq.")
aAdd(_aSize, 40)

aAdd(_aHead , "Total")
aAdd(_aSize, 5)


U_ITListBox( "Listagem de pedidos por gerente" , _aHead , _aCols , .T. , 1 ,"Listagem de pedidos por gerente",_aSize)

Return

/*
===============================================================================================================================
Programa----------: A112MAP
Autor-------------: Jonathan Torioni
Data da Criacao---:  05/08/2020
Descrição---------: Realiza o mapeamento das colunas do oMark
Parametros--------: _cCampo - Recebe o nome da coluna
					_lPesc	- Indica se realiza o mapeamento das colunas
Retorno-----------: _nPos posição da coluna do browser
===============================================================================================================================
*/
Static Function A112MAP(_cCampo, _lPesc)

Local lHtml     := (GetRemoteType() == 5) //Valida se o ambiente é SmartClientHtml
Local _nX		:=	0
Local _nPos		:= 0

Default _cCampo := ""
Default _lPesc := .T.

If _lPesc
	_nPos := aScan(_aArmap, {|x| x[1] == _cCampo})
Else
	If !lHtml
		For _nX := 1 TO Len(oMark:aColumns)
			aAdd(_aArmap, {oMark:aColumns[_nX]:cHeading, _nX})
		Next _nX
	Else
		For _nX := 1 TO Len(oMark:aHeaders)
			aAdd(_aArmap, {oMark:aHeaders[_nX], _nX})
		Next _nX
	EndIf
EndIf

Return _nPos

/*
===============================================================================================================================
Programa----------: A112OMK
Autor-------------: Jonathan Torioni
Data da Criacao---:  04/08/2020
Descrição---------: Monta oMark
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function A112OMK()

Local lHtml     := (GetRemoteType() == 5) //Valida se o ambiente é SmartClientHtml
Local _nX  		:= 0
Local _bLine	:= Nil
Local _cMacro	:= ""

_aColuns := {}
// AO TROCAR AS ORDENS DOS CAMPOS NA TELA TROQUE A ORDEM TB NA TABELA aArr NA GRAVACAO QUANDO VIA HTML NA FUNCAO AOMS112arq() Procure por "ACERTO MANUAL", e TESTE VIA HTML
//QUANDO For HTML O AARR DEVE SER ORDENADO MANUALMENTE, QUANDO NÃO É ELA É REORDENADA AUTOMATICAMENTE NA A112RA()
aAdd(_aColuns,{Space(1), 				"If(aArr[oMark:nAt,01]==cmarca,oOK,oNO)",,,,,,													  01})//01
aAdd(_aColuns,{Space(2), 				"LoadBitmap(GetResources(),U_AOMS1129())",,,,,,													  02})//02
aAdd(_aColuns,{Space(3), 				"LoadBitmap(GetResources(),U_AOMS1128())",,,,,,													  03})//03
aAdd(_aColuns,{"Impresso",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","RIGHT",020,.F.,.F.,					  04})//04
aAdd(_aColuns,{"Dt Emissão",			"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","RIGHT",035,.F.,.F.,					  11})//05
aAdd(_aColuns,{"Dias/Horas Pendentes",	"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,100,.F.,.F.,					  28})//06
aAdd(_aColuns,{"Tipo Entrega",			"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,050,.F.,.F.,					  10})//07
aAdd(_aColuns,{"Dt Entrega",			"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","RIGHT",035,.F.,.F.,					  14})//08
aAdd(_aColuns,{"Filial Faturamento",	"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,050,.F.,.F.,					  06})//09
aAdd(_aColuns,{"Filial Carregamento",	"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,050,.F.,.F.,					  07})//10
aAdd(_aColuns,{"Cond Pgto",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,050,.F.,.F.,					  17})//11
aAdd(_aColuns,{"Id Pedido",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,040,.F.,.F.,					  08})//12
aAdd(_aColuns,{"Tipo",					"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,050,.F.,.F.,					  05})//13
aAdd(_aColuns,{"Cliente/Venda",			"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,100,.F.,.F.,					  27})//14
aAdd(_aColuns,{"Cliente/Remessa",		"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,050,.F.,.F.,					  09})//15
aAdd(_aColuns,{"Valor Pedido",			"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@E 999,999,999.99","LEFT" ,050,.F.,.F.,		  25})//16
aAdd(_aColuns,{"Tp Frete",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","RIGHT",020,.F.,.F.,					  15})//17
aAdd(_aColuns,{"Peso Bruto",			"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@E 999,999.9999","LEFT" ,020,.F.,.F.,		  29})//18
aAdd(_aColuns,{"Desconto",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@E 999,999,999.99","LEFT" ,050,.F.,.F.,	  30})//19
aAdd(_aColuns,{"Obs",					"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,Len(SZW->ZW_OBSCOM)+300,.F.,.F., 20})//20
aAdd(_aColuns,{"Mens NF",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,Len(SZW->ZW_MENNOTA)+300,.F.,.F.,19})//21
aAdd(_aColuns,{"Trans Time",			"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","RIGHT",025,.F.,.F.,					  13})//22
aAdd(_aColuns,{"Dt Carga",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","RIGHT",035,.F.,.F.,					  12})//23
aAdd(_aColuns,{"Tab Preço",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,050,.F.,.F.,					  16})//24
aAdd(_aColuns,{"Vendedor",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,050,.F.,.F.,					  18})//25
aAdd(_aColuns,{"Coordenador",			"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,060,.F.,.F.,					  31})//26
aAdd(_aColuns,{"Gerente",				"aArr[oMark:nAt,"+AllTrim(Str(Len(_aColuns)+1))+"]","@!","LEFT" ,060,.F.,.F.,					  32})//27

If lHtml
	aHeaders:={}
	For _nX := 1 TO Len(_aColuns)
		aAdd(aHeaders,_aColuns[_nX][1])
	Next _nX
Else
	aHeaders:=NIL
EndIf

//TCBrowse():New(          [ nRow ], [ nCol ], [ nWidth ], [ nHeight ]  , [ bLine ]   , [ aHeaders ], [ aColSizes ], [ oWnd ], [ cField ], [ uValue1 ], [ uValue2 ], [ bChange ], [ bLDblClick ]              , [ bRClick ], [ oFont ], [ oCursor ], [ nClrFore ], [ nClrBack ], [ cMsg ], [ uParam20 ], [ cAlias ], [ lPixel ], [ bWhen ], [ uParam24 ], [ bValid ], [ lHScroll ], [ lVScroll ] )
oMark:=TCBrowse():New(   35    ,    01   , 35+nHeight, 01+nwidth    ,             ,    aHeaders ,              , odlg1    ,           ,            ,            ,            , {|| AOMS112N( cmarca  )} ,            ,          ,            ,             ,             ,         ,             ,    "ARRAY",   .T.     ,          ,             ,           ,             ,              )
oMark:SetArray(aarr)
oMark:bHeaderClick := {|| AOMS112ALL( cmarca  ) }

If lHtml
	If Len(aarr) > 0

		For _nX := 1 TO Len(_aColuns)
			_cMacro +=  IIf(_nX == 1 , "{|| { ", ",") + _aColuns[_nX][2] + IIf(_nX == Len(_aColuns), "} }", "")
		Next _nX

		_bLine := &(_cMacro)

		oMark:bLine:= _bLine
	Else//QUANDO NÃO TEM RESGISTROS
		For _nX := 1 TO Len(_aColuns)
			//_cMacro +=  IIf(_nX == 1 , "{|| { ", ",") + " " + IIf(_nX == ATail(_aColuns), "} }", "")
			_cMacro +=  IIf(_nX == 1 , "{|| { ", ",") + " " + IIf(_nX == Len(_aColuns), "} }", "")
		Next _nX

		_bLine := &(_cMacro)

		oMark:bLine:= _bLine
	EndIf

Else

	For _nX := 1 TO Len(_aColuns)
		_cCol := "{ || IIf(Len(aarr)>0,"+_aColuns[_nX][2]+", ' ') }"
		bCol := &(_cCol)

		If Empty(_aColuns[_nX][1])
			oMark:AddColumn(TCColumn():New(_aColuns[_nX][1], bCol,,,,,,.T.,.F.,,,,.F. ) )
		Else
			oMark:AddColumn(TCColumn():New(_aColuns[_nX][1], bCol ,_aColuns[_nX][3],,,_aColuns[_nX][4],_aColuns[_nX][5],_aColuns[_nX][6],_aColuns[_nX][7],,,,,))
		EndIf
	Next _nX
EndIf

Return


/*
===============================================================================================================================
Programa----------: A112RA
Autor-------------: Jonathan Torioni
Data da Criacao---:  04/08/2020
Descrição---------: Reordena o conteúdo do aArr para um novo array para a ordem do A112MAP()
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A112RA()

Local _aTemp := aClone(aArr)
Local _nX  		:= 0
Local _nY		:= 0
Local _nPos		:= 0

For _nX := 1 TO Len(_aTemp)
	For _nY := 1 to Len(_aColuns)
		_nPos := A112MAP(_aColuns[_nY][1])
		AFill(aArr[_nX], _aTemp[_nX][_aColuns[_nY][8]], _nPos, 1)
	Next _nY
	AFill(aArr[_nX], _aTemp[_nX][21], 32,1) //<- RECNO -> Garantir que o RECNO fique sempre na ultima posição do aArr
	AFill(aArr[_nX], _aTemp[_nX][22], 31,1)
	AFill(aArr[_nX], _aTemp[_nX][23], 30,1)
	AFill(aArr[_nX], _aTemp[_nX][24], 29,1)
	AFill(aArr[_nX], _aTemp[_nX][26], 28,1)
Next _nX

Return

/*
===============================================================================================================================
Programa--------: AOMS1123C
Autor-----------: Jerry
Data da Criacao-: 06/05/2021
Descrição-------: Valida Produto para operação 08 para Filial Três Corações
Parametros------: cNumPed   := Código do Pedido
----------------: cFilAux   := Filial do Pedido
				  _lAutoref := Execução de pedidos múltiplos
Retorno---------: lRet := Informa se validou
===============================================================================================================================
*/
Static Function AOMS1123C( cNumPed , cFilAux, _lAutoref )

Local aAreaAux	:= FWGetArea()
Local lOk		:= .T.
Local lbq       := .F.
Local _nQtd3c   := 0
Local _nQtdItem := 0
Local _cProd3c := ""

_cFilSalva  := cFilAnt
cFilAnt     := SZW->ZW_FILIAL
_cProd3c    := SuperGetMV("IT_ZW3C",.T.,"00030010601;00030041401;00030041301;00030070601;00030080601;00050019101;00050010301;00050030301;00030050601;00030023401" )

cFilAnt     := _cFilSalva

SZW->( DBSetOrder(1) )
SZW->( DBSeek( cFilAux + cNumPed ) )
While SZW->( !Eof() ) .And. cFilAux + cNumPed == SZW->( ZW_FILIAL + ZW_IDPED )

	_nQtdItem++

	If (AllTrim(SZW->ZW_PRODUTO) $ _cProd3c)  //Produto Creme e Condensando
		_nQtd3c++
	EndIf

	SZW->(DBSkip())

EndDo

If _nQtd3c > 0

	If _nQtdItem = _nQtd3c
		DBSelectArea("SZW")
		SZW->( DBSetOrder(1) )

		If SZW->( DBSeek( cFilAux + cNumPed ) )

			While SZW->(!Eof()) .And. SZW->( ZW_FILIAL + ZW_IDPED ) == cFilAux + cNumPed

				RecLock("SZW",.F.)
				SZW->ZW_TIPO  := '08'
				SZW->(MSUnLock())
				SZW->(DBSkip())
			EndDo
		EndIf
	Else
		If _lAutoref //Qdo marca vários

			SZW->( DBSetOrder(1) )
			SZW->( DBSeek( cFilAux + cNumPed ) )

			SA1->(DBSetOrder(1))
			SA1->(DBSeek(xFilial("SA1")+SZW->ZW_CLIENTE+SZW->ZW_LOJACLI))

			aAdd(_aResults, {LoadBitmap(GetResources(),"BR_VERMELHO"),cFilAux,AllTrim(cNumPed),SA1->A1_COD+"/"+SA1->A1_LOJA + " - "+AllTrim(SA1->A1_NOME),"Pedido Filial Três Corações, contendo Creme de Leite e Condensando e Outros, não podera ser efetivado com Operação 08"})
		Else
			U_ITMsg("Pedido Filial Três Corações, contendo Creme de Leite e Condensando e Outros, não podera ser efetivado com Operação 08","Validação de Operação 08", 1	)
		EndIf

		lok := .F.
		lBq := .T. //Seta .T. na variável de Controle de Bloqueio de Pedidos

	EndIf
	//Desfaz lock nos registros
	AOMS112UN(cFilAux,cNumPed)
EndIf

FWRestArea(aAreaAux)

Return( lOk )

/*
===============================================================================================================================
Programa--------: AOMS112PM
Autor-----------: Igor Melgaço
Data da Criacao-: 24/05/2021
Descrição-------: Valida Itens do pedido que a qtd não é multipla a Qt. Pallet do Produto
Parametros------: _cCodFil := Filial
----------------: _cNumPed := Numero do pedido
----------------: _cItens  := Itens do pedido que a qtd não é multipla a Qt. Pallet do Produto
----------------: _cDet    := Detalhes dos itens informando a qtd sugerida
Retorno---------: _lRet    := Validação do pedido
===============================================================================================================================
*/
Static Function AOMS112PM(_cCodFil,_cNumPed,_cItens,_cDet)

Local _lRet     := .T.
Local _nQtdMult := 0
Local _nResto   := 0
Local _nQtdPecas:= 0
Local _cQueijo  := "N"
Local _nQtdFator:= 1
Local _cGrpBI   := ""

SZW->( DBSetOrder(1) )
SZW->( DBSeek( _cCodFil + _cNumPed ) )
While SZW->( !Eof() ) .And. _cCodFil + _cNumPed == SZW->( ZW_FILIAL + ZW_IDPED )

	SB1->(DBSetOrder(1))
	If SB1->(DBSeek(xFilial("SB1")+SZW->ZW_PRODUTO))
		_nQtdMult := SB1->B1_I_PCCX
		_cQueijo  := SB1->B1_I_QQUEI
		_nQtdFator:= SB1->B1_I_FATCO
		_cGrpBI   := SB1->B1_I_BIGRP
	EndIf

	If _cQueijo = "S" .And. _nQtdMult > 0 .And. _cGrpBI = "43"

		_nQtdPecas := (SZW->ZW_QTDVEN / _nQtdFator)

		_nResto   := Mod(_nQtdPecas,_nQtdMult)

		If _nQtdMult > 0 .And. _nResto <> 0

			_nMin := IIf(_nQtdPecas < _nQtdMult, 0 ,_nQtdPecas - _nResto)
			_nMax := IIf(_nQtdPecas < _nQtdMult, _nQtdMult ,_nMin + _nQtdMult)

			_cSugest := IIf(_nQtdPecas < _nQtdMult,"  Qtd Sugerida " + AllTrim(transform(_nMax, _cPictQtv )),;
				"  Qtd Sugerida " + AllTrim(transform(_nMin, _cPictQtv )) + " Ou " + AllTrim(transform(_nMax, _cPictQtv )) )

			_cItens += IIf(Empty(AllTrim(_cItens)),"","; ") + SZW->ZW_ITEM

			_cDet += IIf(Empty(AllTrim(_cDet)),"",CRLF) + "Item " + SZW->ZW_ITEM + " Produto " + SZW->ZW_PRODUTO + ;
				" Qtd " + AllTrim(transform(_nQtdPecas, _cPictQtv)) + " Qt.Pc na Cx." + AllTrim(transform(_nQtdMult, _cPictQtv )) + _cSugest

			_lRet   := .F.

		EndIf
	Else
		_lRet   := .T.
	EndIf

	SZW->(DBSkip())

EndDo

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS112MA
Autor-----------: Igor Melgaço
Data da Criacao-: 24/05/2021
Descrição-------: Valida peso acima de 22.000 somente para Produto Matinais 
Parametros------: _cCodFil := Filial
----------------: _cNumPed := Numero do pedido
----------------: _cItens  := Itens do pedido 
----------------: _cDet    := Detalhes dos itens informando a qtd sugerida
Retorno---------: _lRet    := Validação do pedido
===============================================================================================================================
*/
Static Function AOMS112MA(_cCodFil,_cNumPed,_cItens,_cDet)

Local _lRet      := .F.
Local _lProdMat  := 0
Local _nPeso     := 0

SZW->( DBSetOrder(1) )
SZW->( DBSeek( _cCodFil + _cNumPed ) )
While SZW->( !Eof() ) .And. _cCodFil + _cNumPed == SZW->( ZW_FILIAL + ZW_IDPED )

	_lProdMat := ( Posicione("SB1",1,xFilial("SB1") + SZW->ZW_PRODUTO,"B1_I_BIFAM") $ _cProdMat )

	If _lProdMat .And. !(SZW->ZW_LOCAL $ _cArmazMat) .And. ( SZW->ZW_UM $ "KG;G " .Or. SZW->ZW_2UM $ "KG;G ")

		If SZW->ZW_UM $ "KG;G "
			_nPeso  += IIf(SZW->ZW_2UM = "G ",1000,1) * SZW->ZW_QTDVEN
		ElseIf SZW->ZW_2UM $ "KG;G "
			_nPeso  += IIf(SZW->ZW_2UM = "G ",1000,1) * ConvUM( SZW->ZW_PRODUTO,SZW->ZW_QTDVEN,0,Posicione("SB1",1,xFilial("SB1") + SZW->ZW_PRODUTO,"B1_CONV") )
		EndIf

		_cItens += IIf(Empty(AllTrim(_cItens)),"","; ") + SZW->ZW_ITEM

		_cDet += IIf(Empty(AllTrim(_cDet)),"",CRLF) + "Item " + SZW->ZW_ITEM + " Produto " + SZW->ZW_PRODUTO + ;
			" Qtd " + AllTrim(transform(SZW->ZW_QTDVEN, _cPictQtv)) + " Peso " + AllTrim(transform(_nPeso, _cPictQtv )) + " Kg"

	EndIf

	SZW->(DBSkip())

EndDo

If _nPeso > _nPesoMat
	_cDet += CRLF + " Peso Total: " + AllTrim(transform(_nPeso, _cPictQtv)) + " kg"
	_lRet := .T.
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: GeraPedPallet(_aPeds_Pallet,_lAutomatico)
Autor-----------: Igor Fricks
Data da Criacao-: 07/06/2021
Descrição-------: Gera Pedidos de Pallet
Parametros------: 
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================
*/
Static Function GeraPedPallet()

Local _cDesc  	:= "",_cPedPallet
Local _nPreco 	:= _nTotVlrPal:=_nPallet:=0
Local _cUM	  	:= "",_Ped
Local _citls 	:= AllTrim(SuperGetMV('IT_CHEPITS',.T.,'' ) )
Local _citln 	:= AllTrim(SuperGetMV('IT_CHEPITN',.T.,'') )
Local _cclis 	:= AllTrim(SuperGetMV('IT_CHEPCLS',.T.,'') )
Local _cclin 	:= AllTrim(SuperGetMV('IT_CHEPCLN',.T.,'') )
Local _cchep 	:= SuperGetMV("IT_CCHEP",.T.,'')
Local _cpbr 	:= SuperGetMV("IT_PPBR",.T.,'')
Local _cPBRITLP := AllTrim(SuperGetMV('IT_PBRITLP',.T.,'51'))
Local _cPBRCLIP := AllTrim(SuperGetMV('IT_PBRCLIP',.T.,'51'))
Local _nRenoSC5 := SC5->(Recno())
Local _lGerouOK := .T.
Local _clichep := "N"

Default oproc := nil

_aCabPV		:= {}
_aItemPV	:= {}

DBSelectArea("SC6")
DBSetOrder(1)
DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)
While SC5->C5_FILIAL + SC5->C5_NUM == SC6->C6_FILIAL + SC6->C6_NUM .And. SC6->(!Eof())
	_nPallet += SC6->C6_QTDVEN //TRBPED->PED_I_QTPA//Qtde do Pallet
	SC6->(DBSkip())
EndDo

For _Ped := 1 TO 1

	SA2->( DBSetOrder(1) )
	SBZ->( DBSetOrder(1) )
	SC5->( DBSetOrder(1) )

	lMsErroAuto	:= .F.
	nItem		:= 1
	_cDesc      := ""
	_nPreco     := 0
	_cUM	    := ""

	// Verifica se o Cliente esta com Pallet == Sim
	If .T.//Upper( _cUPalet ) $ '1,S' .And. M->C5_I_TIPCA <> "2" // Tipo de Carga (C5_TIPCA) => 1=Paletizada; 2=Batida
		// Verifica se o pedido atual já não está amarrado à um pedido de Pallet
		If .T.//Empty( SC5->C5_I_NPALE )
			// Verifica se houveram vendas com quantidade de Pallets
			If _nPallet > 0

				_cFilOrigem := SC5->C5_FILIAL
				_cPedOrigem := SC5->C5_NUM
				cTipoPV		:= SC5->C5_TIPO
				cCliente	:= SC5->C5_CLIENTE
				cLoja		:= SC5->C5_LOJACLI
				_dDtEnt		:= If(SC5->C5_I_DTENT < DATE(),DATE(),SC5->C5_I_DTENT)//Para nao travar a criacao do Pedido de Pallet
				_cLocal     := Posicione('SC6',1,SC5->C5_FILIAL+SC5->C5_NUM,"C6_LOCAL")

				cTpOper		:= ''

				// Verifica se no cadastro do Cliente É CLIENTE CADASTRADO NA CHEP
				_clichep := "N"
				SA1->(DBSetOrder(1))
				If SA1->( DBSeek( xFilial("SA1") + ( cCliente + cLoja ) ) )

					If Len(AllTrim(SA1->A1_I_CCHEP)) == 10
						_clichep := "S"
					EndIf

					_TipoC := SA1->A1_I_CHEP

					If !Empty(SA1->A1_I_PALET)
						_cPallet:= SA1->A1_I_PALET
					EndIf

				EndIf

				If Empty(_TipoC)
					_TipoC := "C"
				EndIf

				_cTipoPed := "2"

				If !SC5->C5_TIPO $ "B/D"//Se NÃO For beneficiamento e Devolução
					If _cPallet $ "S,1"
						//Esse controle é pela a origem dos dados para deixar alterar o tipo de carga inclusive se o usuario já alterou, saiu e entrou na tela de novo
						_cTipoPed := IIf(_TipoC = "C","1","3")
					Else
						_cTipoPed := "2"
					EndIf
				EndIf

				If _cTipoPed  $ "3,6"//"3-Pallet PBR","6-Pallet PBR Retorno"
					_TipoC:="P"
				EndIf

				If _TipoC == "C" //Pallet Chep
					If cCliente == '000001'
						cTpOper := IIf(_clichep == "S",_citls,_citln)
					Else
						cTpOper := IIf(_clichep == "S",_cclis,_cclin)
					EndIf
				ElseIf _TipoC == "P" //Pallet PBR
					cTpOper := IIf(cCliente == '000001',_cPBRITLP,_cPBRCLIP)
				EndIf

				// Monta o cabeçalho do pedido de Pallet
				_aCabPV :={	{ "C5_TIPO"		, cTipoPV			, Nil },; // Tipo de pedido
				{ "C5_I_OPER"	, cTpOper			, Nil },; // Tipo da operacao
				{ "C5_FILIAL"	, _cFilOrigem   	, Nil },; // filial
				{ "C5_CLIENTE"	, cCliente			, Nil },; // Codigo do cliente
				{ "C5_LOJAENT"	, cLoja				, Nil },; // Loja para entrada
				{ "C5_LOJACLI"	, cLoja				, Nil },; // Loja do cliente
				{ "C5_EMISSAO"	, Date()			, Nil },; // Data de emissao
				{ "C5_CONDPAG"	, '001'				, Nil },; // Codigo da condicao de pagamanto*
				{ "C5_TIPLIB"	, "1"				, Nil },; // Tipo de Liberacao
				{ "C5_MOEDA"	, 1					, Nil },; // Moeda
				{ "C5_LIBEROK"	, " "				, Nil },; // Liberacao Total
				{ "C5_TIPOCLI"	, "F"				, Nil },; // Tipo do Cliente
				{ "C5_I_NPALE"	, _cPedOrigem		, Nil },; // Numero que originou a pedido de palete
				{ "C5_I_PEDPA"	, "S"				, Nil },; // Pedido Refere a um pedido de Pallet
				{ "C5_I_DTENT"	, _dDtEnt			, Nil } } // Dt de Entrega

				// Quando Pedido de Pallet Retorno e For Troca Nota o Pedido deve ser gerado na Filial de Carregamento
				If _cTipoPed  $ "1,3,4"
					aAdd( _aCabPV, { "C5_I_TRCNF", If(Empty(SC5->C5_I_TRCNF),"N",SC5->C5_I_TRCNF), Nil } )
					aAdd( _aCabPV, { "C5_I_FILFT", SC5->C5_I_FILFT, Nil } )
					aAdd( _aCabPV, { "C5_I_FLFNC", SC5->C5_I_FLFNC, Nil } )
				EndIf

				// Verifica o Tipo de Pallet e recupera o código do Produto referente
				If _TipoC == "C"
					_cProduto := _cchep
				ElseIf _TipoC == "P"
					_cProduto := _cpbr
				EndIf
				// Localiza armazém do produto
				If _cLocal != '36'

					_cLocal := ""

					If SBZ->( DBSeek( xFilial('SBZ') + _cProduto ) )
						_cLocal := SBZ->BZ_LOCPAD
					EndIf

				EndIf

				// Localiza nome do produto, preço e UM
				SB1->(DBSetOrder(1))
				If SB1->(DBSeek(xFilial("SB1")+_cProduto))
					_cDesc := AllTrim(SB1->B1_DESC)
					_nPreco:= SB1->B1_PRV1
					_cUM	  := SB1->B1_UM
				EndIf

				_nTotVlrPal   := _nPallet * _nPreco

				// Monta o item do pedido de Pallet
				aAdd( _aItemPV , {	{ "C6_ITEM"		, StrZero( nItem , 2 )	, Nil },; // Numero do Item no Pedido
				{ "C6_FILIAL"	, _cFilOrigem			, Nil },;
					{ "C6_PRODUTO"	, _cProduto				, Nil },; // Codigo do Produto
				{ "C6_QTDVEN"	, _nPallet				, Nil },; // Quantidade Vendida
				{ "C6_PRCVEN"	, _nPreco				, Nil },; // Preco Unitario Liquido
				{ "C6_PRUNIT"	, _nPreco				, Nil },; // Preco Unitario Liquido
				{ "C6_ENTREG"	, _dDtEnt				, Nil },; // Data da Entrega
				{ "C6_SUGENTR"	, _dDtEnt				, Nil },; // Data da Entrega
				{ "C6_VALOR"	, _nTotVlrPal			, Nil },; // valor total do item
				{ "C6_UM"		, _cUM					, Nil },; // Unidade de Medida Primar.
				{ "C6_LOCAL"	, _cLocal				, Nil },; // Almoxarifado
				{ "C6_DESCRI"	, _cDesc				, Nil },; // Descricao
				{ "C6_QTDLIB"	, 0						, Nil }}) // Quantidade Liberada

				_lMsgEmTela  := .F.
				// Geração do  pedido de Pallet
				MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItemPV , 3 )

			_lMsgEmTela  := .T.
				
			If lMsErroAuto

					If ( __lSx8 )
						RollBackSx8()
					EndIf

					_cMsgEfetiva := " Pedido_"+AllTrim(_cPedOrigem)+" - "+AllTrim(MostraErro("\system\", "Pedido_"+AllTrim(SC5->C5_NUM)+"_"+DToS(Date())+"_"+StrTran(Time(),":","-")+".log")) // Esta mensagem será retornada na integração com Webservice Italac x RDC.
					_cMsgEfetiva := " Ocorreram problemas na Geração de Pedidos de Pallet: " + StrTran(_cMsgEfetiva,Chr(10)+Chr(13),"")

					SC5->( DBGoTo( _aPeds_Pallet[_Ped,1] ))
					_cMensagem:='Erro ao gerar o Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")+" ,"+_cMensagem
					_cCliente:=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME") )

					aAdd( _aLog , {.F.,SC5->C5_NUM,"Nao gerado",_cMensagem  ,_cCliente,cTpOper ,_cLocal  ,SC5->C5_I_FLFNC      ,SC5->C5_I_FILFT     } )

					_lGerouOK:=.F.
					Loop //do For

				Else
					//Regrava por garantia
					SC5->( RecLock( 'SC5' , .F. ) )
					SC5->C5_I_NPALE := _cPedOrigem
					SC5->C5_I_PEDPA := 'S'//É o Pedido de Pallet
					SC5->C5_I_PEDGE := ''
					SC5->( MSUnLock() )

					_cCliente  := SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME") )
					_cMensagem := 'Gerou o Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")
					U_ITCONOUT(_cMensagem+": "+SC5->C5_NUM)

					aAdd( _aLog , {.T.,_cPedOrigem,SC5->C5_NUM,_cMensagem   ,_cCliente,cTpOper ,_cLocal  ,SC5->C5_I_FLFNC      ,SC5->C5_I_FILFT     } )

					SC6->(DBSetOrder(1))
					SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )//Posiciono por garantia

					// Faz a amarração do pedido de origem no pedido de Pallet
					_cPedPallet := SC5->C5_NUM
					If SC5->( DBSeek( _cFilOrigem + _cPedOrigem ) )
						SC5->( RecLock( 'SC5' , .F. ) )
						SC5->C5_I_NPALE := _cPedPallet
						SC5->C5_I_PEDPA := ''
						SC5->C5_I_PEDGE := 'S' //É o Pedido Gerador de Pallet
						SC5->( MSUnLock() )
					EndIf
				EndIf

			EndIf

		Else
			U_ITCONOUT("Pedido:"+_cPedOrigem+" sem quantidade de Pallet")
		EndIf
	EndIf
Next

SA1->(DBSetOrder(1))

SC5->(DBGoTo(_nRenoSC5))

Return _lGerouOK

/*
===============================================================================================================================
Programa--------: AOMS112PB(_cCodFil,_cNumPed)
Autor-----------: Igor Fricks
Data da Criacao-: 07/06/2021
Descrição-------: Contabiliza peso do Pedido
Parametros------: 
Retorno---------: Lógico (.T.) Se acima de 5.000
===============================================================================================================================
*/
Static Function AOMS112PB(_cCodFil,_cNumPed)

Local _lRet     := .F.
Local _aAreaSZW := GetArea("SZW")
Local _nPeso    := 0
Local _nPesoMinimo:=SuperGetMV("IT_PBMITN",.T.,5000)
Default _cCodFil := ""
Default _cNumPed := ""

SZW->( DBSetOrder(1) )
SZW->( DBSeek( _cCodFil + _cNumPed ) )
While SZW->( !Eof() ) .And. AllTrim( _cCodFil + _cNumPed) == AllTrim(SZW->( ZW_FILIAL + ZW_IDPED ))
	_nPeso  += SZW->ZW_QTDVEN * Posicione("SB1",1,xFilial("SB1") + SZW->ZW_PRODUTO,"B1_PESBRU")
	SZW->(DBSkip())
EndDo

If _nPeso >= _nPesoMinimo
	_lRet := .T.
EndIf

FWRestArea(_aAreaSZW)

Return _lRet

/*
===============================================================================================================================
Programa--------: AOM112Magro()
Autor-----------: Alex Wallauer
Data da Criacao-: 14/07/2021
Descrição-------: LISTA DOS % DE LEITE MAGRO
Parametros------: _aListaPerc
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOM112Magro(_aListaPerc)

Local _aSize:={"40","40","40","40"}
Local _cMsgTop:=NIL
Local _cTitAux:="LISTA DOS % DE LEITE MAGRO"
Local _aCabPT:={"","Pedido","Qtde Magro","Qtde Integral","% Magro"}
Local _bLegenda:={|C,L| U_AOMS12Leg(C,L) }

//         ITListBox(_cTitAux, _aHeader , _aCols       , _lMaxSiz ,  nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda)
lRet:=U_ITLISTBOX(_cTitAux, _aCabPT  , _aListaPerc  , .F.      , 4      , _cMsgTop ,          , _aSize  ,         ,     ,        ,          ,       ,        ,          ,           ,_bLegenda)

Return .T.

/*
===============================================================================================================================
Programa--------: AOMS12Leg()
Autor-----------: Alex Wallauer
Data da Criacao-: 29/04/2021
Descrição-------: DEVOLVE AS CORES PARA A LEGENDA
Parametros------: _aCol,_nLinha
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS12Leg(_aCol,_nLinha)

Local oVerm := LoadBitmap( , "BR_VERMELHO")// VERMELHO TEM QUE GERA REPOSICAO .F. CRITICO
Local oAzul := LoadBitmap( , "BR_AZUL"    )// AZUL TEM QUE GERA REPOSICAO .F. MAS TEM AINDA
Local oVerd := LoadBitmap( , "BR_VERDE"   )// VERDE ESTOQUE TUDO OK .T.

If Val(_aCol[_nLinha,5]) <> 0
	Return oVerd
ElseIf Val(_aCol[_nLinha,4]) <> 0
	Return oAzul
EndIf

Return oVerm

/*
===============================================================================================================================
Programa--------: AOM112BoniApro()
Autor-----------: Alex Wallauer
Data da Criacao-: 19/07/2021
Descrição-------: Valida se o Cliente possui pedido(s) de Bonificacao sem aprovação
Parametros------: cCodCli , cLojCli , _cPSB
Retorno---------: .T. OU .F.
===============================================================================================================================
*/
Static Function AOM112BoniApro(cCodCli , cLojCli , _cPSB )

Local cAlias	:= GetNextAlias()
Local _cQuery	:= ""

_cQuery := " SELECT DISTINCT SZW.ZW_IDPED "
_cQuery += " FROM "+ RetSqlName("SZW") +" SZW "
_cQuery += " WHERE  SZW.ZW_NUMPED 	= ' ' "
_cQuery += " AND	SZW.ZW_CLIENTE	= '"+ cCodCli +"' "
_cQuery += " AND	SZW.ZW_LOJACLI	= '"+ cLojCli +"' "
_cQuery += " AND	SZW.ZW_TIPO	    = '10' "
_cQuery += " AND	SZW.ZW_STATUS NOT IN ('Q','R','E','C') "
_cQuery += " AND	SZW.ZW_BLOQ     <> 'R' "
_cQuery += " AND    SZW.D_E_L_E_T_	= ' ' "

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf
DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
_cPSB:=""
(cAlias)->( DBGoTop() )
While (cAlias)->(!Eof())
	_cPSB += "[ "+AllTrim((cAlias)->ZW_IDPED)+" ] "
	(cAlias)->(DBSkip())
EndDo
(cAlias)->( DBCloseArea() )
DBSelectArea("SZW")

Return Empty(_cPSB)

/*
===============================================================================================================================
Programa----------: AOM112F3()
Autor-------------: Alex Wallauer
Data da Criacao---: 030/07/2018
Descricao---------: Função usada no F3: F3ITLC
Parametros--------: Nenhum
Retorno-----------: Tipos de pedidos
===============================================================================================================================*/
User Function AOM112F3()

Local  _aF3Novo :={}
aAdd(  _aF3Novo , "01=Pedido com Crédito Rejeitado [Laranja]")
aAdd(  _aF3Novo , "02=Pedido com Cliente/Remessa Bloqueado [X Vermelho] ")
aAdd(  _aF3Novo , "03=Pedido Bonificação Bloqueadoo [Marrom Ocean]")
aAdd(  _aF3Novo , "04=Pedido Bonificação Rejeitado [Marrom Quadrado]")
aAdd(  _aF3Novo , "05=Pedido com Preço Rejeitado [Violeta]")
aAdd(  _aF3Novo , "06=Pedido com Preço Bloqueado [Preto]")
aAdd(  _aF3Novo , "07=Pedido com Preço Liberado [Verde]")
aAdd(  _aF3Novo , "08=Pedido com Crédito Bloqueado [Azul]")
aAdd(  _aF3Novo , "09=Pendente Aprov. Preço P/Coordenador [Amarelo]")
aAdd(  _aF3Novo , "10=Pendente Aprov. Preço P/Gerente [Verde Escuro]")
aAdd(  _aF3Novo , "11=Pedido aguardando Efetivação [Vermelho]")

Return _aF3Novo

/*
===============================================================================================================================
Programa--------: SOMS112S
Autor-----------: Alex Wallauer
Data da Criacao-: 10/03/2022
Descrição-------: Efetivação dos pedidos de vendas do portal automatica
Parametros------: _lTela - Se .T. mostra as telas
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function SOMS112S(_lTela)//U_SOMS112S(.T.)

Local _nnm
Local _cAlias := GetNextAlias()
Local _cQuery := ""
Local _aPeds  :={}
Private _alista := {}
Private _otemp := nil
Private _ccodclip := ""
Private _cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.T.,"05,42"))// Tipos de operações da operação trigular
Private _cOperFat       := LEFT(_cOperTriangular,2)
Private _cOperRemessa   := RIGHT(_cOperTriangular,2)
Private aarr := {}
Private aheader := {}
// Variáveis abaixo utilizadas na efetivação do pedido do portal. Na chamada do MSEXECAUTO.
Private _cOperTri   := Space(1)  // Esta variável será utilizada no fonte MT410TOK para peencher o campo operação triangular.
Private _cCodClien  := Space(6)  // Esta variável será utilizada no fonte MT410TOK para peencher o campo codigo Cliente/Venda.
Private _cLojaClie  := Space(4)  // Esta variável será utilizada no fonte MT410TOK para peencher o campo loja Cliente/Venda.

Default _lTela := !FWGetRunSchedule()

If _lTela
	If !U_ITMsg("Confirma Geração de Pedidos",'Atenção!',,1,2,2)
		Return .F.
	EndIf
EndIf

_cQuery += " SELECT DISTINCT ZW_FILIAL, ZW_IDPED, Case WHEN ZW_TIPO = '10' THEN 'A ' Else 'B' END ORD , "
_cQuery += " (SELECT MIN(R_E_C_N_O_) FROM "+ RETSQLNAME('SZW') +" B WHERE B.ZW_IDPED = SZW.ZW_IDPED) NRRECNO "
_cQuery += " FROM  "+ RETSQLNAME('SZW') +" SZW "
_cQuery += " WHERE "+ RETSQLDEL('SZW')
_cQuery += " AND SZW.ZW_EMISSAO >= '20240101'
_cQuery += " AND SZW.ZW_STATUS = 'L' "
_cQuery += " AND SZW.ZW_ITEM = '1 ' "
_cQuery += " AND SZW.ZW_NUMPED = ' ' "
_cQuery += " AND SZW.ZW_ENVWF <> ' ' " //Somente listar Pedido que já foi avaliado pela rotina MOMS050 - WF DE PREÇO
_cQuery += " AND NOT EXISTS (SELECT 'Y' FROM "+ RETSQLNAME('SZW') +" SZWB WHERE SZWB.ZW_IDPED = SZW.ZW_IDPED "
_cQuery += " AND SZWB.ZW_BLOPRC IN ('B', 'R') AND SZWB.ZW_BLQLCR IN ('B','R','Z') ) "
_cQuery += " ORDER BY ORD, NRRECNO "

TCQUERY _cQuery NEW ALIAS (_cAlias)

(_cAlias)->( DBGoTop() )

While (_cAlias)->(!Eof())

	aAdd(_aPeds,(_cAlias)->ZW_FILIAL+(_cAlias)->ZW_IDPED)

	(_cAlias)->(DBSkip())

EndDo

If Len(_aPeds) == 0

	If _lTela
		U_ITMsg("Nenhum pedido selecionado","Atenção","Selecione ao menos um pedido para efetivar",1)
	EndIf

Else

	If Len(_aPeds) > 0

		SZW->( DBSetOrder(1) )
		_aResults := {}
		_ntot := Len(_aPeds)
		//Realiza efetivação dos pedidos
		For _nnm := 1 to _ntot

			If SZW->( DBSeek( _aPeds[_nnm] ) ) .And. SZW->ZW_STATUS = 'L' .And. SZW->ZW_NUMPED = ' ' .And. SZW->ZW_ENVWF <> ' '
				_nni := _nnm
				cFilAnt := SZW->ZW_FILIAL
				If _lTela
					FWMsgRun(,{|oproc| AOMS112EFE(SZW->ZW_IDPED , SZW->ZW_FILIAL,.T.,_lTela)},"Pedido: "+_aPeds[_nnm],"Efetivando pedido " + StrZero(_nnm,4) + " de " + StrZero(_ntot,4) +"...")
				Else
					AOMS112EFE(SZW->ZW_IDPED , SZW->ZW_FILIAL,.T.,_lTela)
				EndIf
			EndIf

		Next

		If Len(_aResults) > 0
			_aCab:={' ','Filial','Pedido','Cliente/Remessa','Resultado / Erros',"Complemento do Resultado / Erros"}
			For _nnm := 1 TO Len(_aResults)
				If Len(_aResults[_nnm]) < 6
					ASize( _aResults[_nnm] , 6 )
					_aResults[_nnm,6]:=" "
				EndIf
			Next
			If _lTela
				U_ITListBox( "Efetivação de pedidos do portal" , _aCab , _aResults , .T. , 1,"Resultado do processamento" )
			EndIf
			_cLinha:=ARRTOKSTR(_aCab,";")+CRLF
			For _nnm := 1 TO Len(_aResults)
				_cLinha+=ARRTOKSTR(_aResults[_nnm],";")+CRLF
			Next
			_cLinha:=StrTran(_cLinha,".",",")
			_cdir := "\data\Italac\AOMS112\"
			_cFileNome:=_cdir+"AOMS112_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".CSV"
			MemoWrite(_cFileNome,_cLinha)
		Else

			If _lTela
				U_ITMsg("Nenhum pedido efetivado!","Atenção",,1)
			EndIf

		EndIf

	Else

		If _lTela
			U_ITMsg("Nenhum registro encontrado!","Atenção",,1)
		EndIf

	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: AOM112RC()
Autor-------------: Jerry
Data da Criacao---: 22/03/2022
Descricao---------: Função usada para chamada da Gravação da Recusa via Scheduler MOMS050
Parametros--------: cFilPed, nIdPed
Retorno-----------: _dDataOriginal
===============================================================================================================================*/
User Function AOM112RC(cFilPed, nIdPed, cMotivo)
	
AOMS112GRC(cFilPed, nIdPed,"AUTO",cMotivo)

Return

User Function DTVAL112(_dDataOriginal)

Local _nI     := 0
Local _nDiasMax  := SuperGetMV("IT_MAXDIAS",.T.,7)


While _nI < _nDiasMax

	
	_dDataOriginal := (_dDataOriginal + 1 )

	If _dDataOriginal =  DataVAlida( _dDataOriginal, .T. )
		_nI++
	EndIf 
	
EndDo

Return(_dDataOriginal)

/*
===============================================================================================================================
Programa----------: AOM112AP()
Autor-------------: Igor Melgaço
Data da Criacao---: 02/06/2022
Descricao---------: Função usada para visualizar dados da aprovação
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
User Function AOM112AP()

Local _oDlg
Local _cGData:= ""
Local _cGHora:= ""
Local _cCData:= ""
Local _cCHora:= ""
Local _cObs  := ""
Local _nCol1 := 007
Local _nCol2 := 105
Local _nLinha:= 007

If Len(aarr) = 0
   U_ITMsg("Não há registros para visualizar.",'Atenção!',"Altere o filtro para trazer registros validos.",1)
   Return .F.
EndIf

SZW->(DBSetOrder(1))
SZW->(DBSeek(LEFT(AllTrim(aarr[oMark:naT,A112MAP("Filial Faturamento")]),2)+AllTrim(aarr[oMark:naT,A112MAP("Id Pedido")]) ))
_cGData:= SZW->ZW_I_DLIBG
_cGHora:= LEFT(SZW->ZW_I_HLIBG,5)
_cCData:= SZW->ZW_DATAAPR 
_cCHora:= SZW->ZW_HORAAPR 
_cObs  := SZW->ZW_I_OBS

DEFINE MSDIALOG _oDlg TITLE "Dados de Aprovação de Pedido " FROM 000,000 TO 300,470 PIXEL

	@ _nLinha, _nCol1 Say "Data de Aprovação do Gerente:" PIXEL
	@ _nLinha, _nCol2 MSGET _cGData  SIZE 50,11 OF _oDlg  PIXEL When .F.
	_nLinha+=15

	@ _nLinha, _nCol1 Say "Hora de Aprovação do Gerente:" PIXEL
	@ _nLinha, _nCol2 MSGET _cGHora SIZE 50,11 OF _oDlg PIXEL When .F.
	_nLinha+=15

	@ _nLinha, _nCol1 Say "Data de Aprovação do Coordenador:" PIXEL
	@ _nLinha, _nCol2 MSGET _cCData  SIZE 50,11 OF _oDlg  PIXEL When .F.
	_nLinha+=15

	@ _nLinha, _nCol1 Say "Hora de Aprovação do Coordenador:" PIXEL
	@ _nLinha, _nCol2 MSGET _cCHora SIZE 50,11 OF _oDlg PIXEL When .F.
	_nLinha+=15

	@ _nLinha, _nCol1 Say "Observação:" PIXEL
	_nLinha+=15
	@ _nLinha, _nCol1 GET _cObs MEMO SIZE 220,50 MEMO OF _oDlg PIXEL WHEN .F.

Activate MSDialog _oDlg Centered

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS112Q()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/09/2022
Descricao---------: Alterar pedido de vendas do portal, conforme regras estabelecidas para filial "93".
                    No momento da efetivação. Chamado 41299.
Parametros--------: _cCodFil = Filial do Pedido
                    _cIdPed  = NUMERO DO PEDIDO /PORTAL
					_cfilpro = Filial de Carregamento.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS112Q(_cCodFil , _cIdPed ,_cfilpro)

Local _aRegsSZW := {}
Local _lHaArmaz38 := .F.
Local _nI 
Local _cLocFrisia := SuperGetMV("IT_LOCFRIS",.T.,"38")
Local _cLocProd

Begin Sequence 
   
   SBZ->( DBSetOrder(1) ) // BZ_FILIAL+BZ_COD

   SZW->( DBSetOrder(1) )
   SZW->( DBSeek( _cCodFil + _cIdPed ) )

   While SZW->( !Eof() ) .And. _cCodFil + _cIdPed == SZW->( ZW_FILIAL + ZW_IDPED )

      aAdd(_aRegsSZW, SZW->(Recno()))
	  If _lHaArmaz38
	     SZW->(DBSkip())
	     Loop//SÓ PARA NÃO FICAR DANDO SEEK NO SBZ EM TODOS
	  EndIf
      
	  _cLocProd := "ZZ"
	  If SBZ->(MsSeek(_cCodFil+ SZW->ZW_PRODUTO)) //.Or. SBZ->(MsSeek(_cfilpro+ SZW->ZW_PRODUTO))
	     _cLocProd := SBZ->BZ_LOCPAD 
	  EndIf

      If _cLocProd $ _cLocFrisia // "38"
		 _lHaArmaz38 := .T.
	  EndIf

	  SZW->(DBSkip())

   EndDo
   
   For _nI := 1 To Len(_aRegsSZW)
       SZW->(DBGoTo(_aRegsSZW[_nI]))

	   If _lHaArmaz38 //.And. _lSoLocal38
          SZW->(RecLock("SZW",.F.))
          SZW->ZW_TIPO  := "26"  // Alterar ZW_TIPO para 26
          SZW->ZW_LOCAL := "38"  // Alterar ZW_LOCAL para 38
          SZW->(MSUnLock())
       EndIf 

   Next 

End Sequence 

Return

/*
===============================================================================================================================
Programa--------: Ver_Lib_PV(cChave)
Autor-----------: Alex Wallauer
Data da Criacao-: 30/01/2020
Descrição-------: Verefica se no SC9 esta tudo OK ou tenta liberar o Pedido
Parametros------: cChave: Filia + Pedido, _aRecProdSZW: {PRODUTO,RECNO DO SZW}
Retorno---------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
Static Function Ver_Lib_PV(cChave,_aRecProdSZW)

Local _lOK:=.T.//Não Tem erro
Local _nQtdLib:=0
Local _lLiberou:=.T.

SC6->( DBSetOrder(1) )//C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
If !SC6->( DBSeek( cChave ) )
	_lOK:=.F.//Tem erro
EndIf

SC9->(DBSetOrder(1) )//
SC6->(DBSetOrder(1))
While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == cChave
	
	_lOK:=.T.
	
	If !SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
		_nQtdLib := MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN)//LIBERA ITEM DO PEDIDO
	EndIf
	
	If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
		If SC9->C9_QTDLIB <> SC6->C6_QTDVEN
			_lOK:=.F.//Tem erro
		ElseIf !Empty(SC9->C9_BLEST)
			_lOK:=.F.//Tem erro
		EndIf	    
		If _lOK .And. !(Empty(SC9->C9_BLCRED))
           SC9->(RecLock("SC9",.F.))
  		   SC9->C9_BLCRED := " "	   
	   	   SC9->(MSUnLock("SC9"))
	   		
	       //Faz análise e liberação de estoque pois o padrão não analisa estoque se o crédito está bloqueado
	       //Posiciona SC6 pois a função A440VerSb2 depende do SC6 posicionado para analisar o estoque
	       If SC6->(DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO+SC9->C9_ITEM)) .And. A440VerSB2(SC9->C9_QTDLIB)
	       	  If !(Empty(SC9->C9_BLEST))
	       	     SC9->(RecLock("SC9",.F.))
		         SC9->C9_BLEST := ""
	   	         If !(MaAvalSC9("SC9",5,{{ "","","","",SC9->C9_QTDLIB,SC9->C9_QTDLIB2,Ctod(""),"","","",SC9->C9_LOCAL}}))
	   	            SC9->C9_BLEST := "02"
			        _lOK:=.F.//Tem erro
	   	         EndIf	
	             SC9->(MSUnLock("SC9"))
	          EndIf
	   	   EndIf	
   	    EndIf	
	Else
	   _lOK:=.F.//Tem erro
	EndIf
    If !_lOK //Tem erro
	   _lLiberou:=.F.
	   If (nPos:= aScan(_aRecProdSZW, {|P| P[1] == SC6->C6_PRODUTO  })) > 0
		   _aRecProdSZW[nPos,3]:="Produto "+SC6->C6_PRODUTO+" com quantidade de Estoque insuficiente"
	   EndIf	
	EndIf

	SC6->( DBSkip() )
	
EndDo

Return _lLiberou

/*
===============================================================================================================================
Programa--------: CorrigeItem
Autor-----------: Alex Wallauer
Data da Criacao-: 10/05/2024
Descrição-------: Verefica se o C6_ITEM esta igual ao ZW_ITEM
Parametros------: aCorrigeItem,_cChavePed
Retorno---------: (.T.) Tá tudo OK
===============================================================================================================================*/
Static Function CorrigeItem(aCorrigeItem As Array,_cChavePed As Character) As Logical

Local aChaveUnica:= {} As Array
Local _cLog      := "" As Character
Local _lGravaLog :=.F. As Character
Local nConta     := 0  As Numeric
Local cConta     := "" As Character
Local lCorrige   := GetMV( "IT_CORITEM",,.T.) As Logical
Local _cFileNome := "" As Character 

Default _cChavePed:=SC5->C5_FILIAL + SC5->C5_NUM

//Indice 12 pq não pode ter o campo C6_ITEM no indice pois vai ser atualizado.
SC6->(DBSetOrder(12))//C6_FILIAL+C6_NUM+C6_PRODUTO+C6_SOLCOM

SC6->(DBSeek(_cChavePed))
_cLog+="Usuario ......................: "+Posicione("SRA",1,SC5->C5_I_CDUSU,"RA_NOME")+CRLF
_cLog+="Data e Hora ..................: "+DToC(Date())+" as "+Time()+CRLF
_cLog+="Pedido do Protheus ...........: "+SC5->C5_FILIAL +" "+ SC5->C5_NUM+CRLF
_cLog+="Pedido do Portal .............: "+SC5->C5_I_IDPED+CRLF
aChaveUnica:={}
nConta:=0
While _cChavePed == SC6->C6_FILIAL + SC6->C6_NUM .And. SC6->(!Eof())
	nConta++
	cConta:=StrZero(nConta,3)
	_cLog+="Produto "+cConta+" do SC6............: "+SC6->C6_FILIAL +" "+ SC6->C6_NUM +" "+ SC6->C6_PRODUTO +" "+ SC6->C6_ITEM+CRLF
	If SC6->C6_ITEM = "00" .Or. aScan(aChaveUnica,SC6->C6_FILIAL + SC6->C6_NUM + SC6->C6_PRODUTO) > 0
		_lGravaLog :=.T.
	EndIf
	aAdd(aChaveUnica, SC6->C6_FILIAL + SC6->C6_NUM + SC6->C6_PRODUTO + SC6->C6_ITEM)
	SC6->(DBSkip())
EndDo
If _lGravaLog 
	_cFileNome:="\data\Italac\aoms112\"+"aoms112_item00_A_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".TXT"
	MemoWrite(_cFileNome,_cLog)
EndIf
SC6->(DBSeek(_cChavePed))
While _cChavePed == SC6->C6_FILIAL + SC6->C6_NUM .And. SC6->(!Eof())
	If (nPos:=aScan(aCorrigeItem,{|I| I[1] == SC6->C6_PRODUTO })) > 0
		_cLog+="Produto no SZW ...............: "+AllTrim(SC6->C6_PRODUTO) +" ["+aCorrigeItem[nPos,2]+"]"+CRLF
		If SC6->C6_ITEM = "00" .And. SC6->C6_ITEM <> aCorrigeItem[nPos,2]
			_lGravaLog :=.T.
			_cLog+="Achou Item diferente no Portal: Prod.: "+AllTrim(SC6->C6_PRODUTO)+" SC6: {"+SC6->C6_ITEM+"} <> SZW: {"+aCorrigeItem[nPos,2]+"}"+CRLF
			If lCorrige .And. Val(aCorrigeItem[nPos,2]) > 0 .And. aScan(aChaveUnica,SC6->C6_FILIAL + SC6->C6_NUM + SC6->C6_PRODUTO + aCorrigeItem[nPos,2]) = 0
				_cLog+="CORRIGIU Item no Protheus.....: "+AllTrim(SC6->C6_PRODUTO) +" DE {"+SC6->C6_ITEM+"} PARA {"+aCorrigeItem[nPos,2]+"}"+CRLF
				SC6->( RecLock( "SC6", .F. ) )
				SC6->C6_ITEM := aCorrigeItem[nPos,2]//Não tem problema de repetir o C6_ITEM pq a chave unica é C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
				SC6->( MSUnLock())
			Else
				_cLog+="NAO corrigiu Item no Protheus : "+AllTrim(SC6->C6_PRODUTO) +" DE {"+SC6->C6_ITEM+"} PARA {"+aCorrigeItem[nPos,2]+"}"+CRLF
			EndIf
		EndIf
	Else
		_cLog+="NAO Achou Item/Prod. no Portal: "+ALTRIM(SC6->C6_PRODUTO) +CRLF
	EndIf 
	SC6->(DBSkip())
EndDo
If _lGravaLog
	_cFileNome:="\data\Italac\aoms112\"+"aoms112_item00_D_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".TXT"
	MemoWrite(_cFileNome,_cLog)
EndIf
SC6->(DBSetOrder(1))//C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS112X
Autor-------------: Igor Melgaço
Data da Criacao---: 16/08/2024
Descrição---------: Altera Marcados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112X()

Local aCoors 	:= {}
Local aSize    := {}
Local aObjects	:= {}
Local oDlg		:= Nil
Local oFont		:= Nil
Local cTitAux	:= "Alterar Selecionados"

Private C5_I_AGEND := ""

If AOMS112VM()

   aCoors 	:= FWGetDialogSize(oMainWnd)
   aSize    := MsAdvSize( .T. ) 

   aAdd( aObjects , { 100 , 100 , .T. , .T. } )
   aInfo   := { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 2 }
   aPosObj := MsObjSize( aInfo , aObjects )

   DEFINE FONT oFont NAME "Verdana" SIZE 05,12

   C5_I_AGEND := Space(Len(TRBF->TPCAR))
   dDataEnt   := CTOD("")
   cOper      := Space(Len(TRBF->TIPO ))
   cFilCar    := Space(Len(TRBF->FILIAL))
   cFilFat    := Space(Len(TRBF->FILIAL))
   cNomeCar   := Space(50)
   cNomeFat   := Space(50)

   nLin := 5
   nCol := 10
   nCol2 := 80

   DEFINE MSDIALOG oDlg TITLE OemToAnsi(cTitAux) From 03,0 To 17,50  //"OPs em Aberto deste Produto"

   	  @ nLin , nCol  Say 'Tipo de Agendamento' OF oDlg PIXEL 
      @ nLin , nCol2 MSGET oTipo Var C5_I_AGEND  SIZE 50,09  PIXEL F3 "LSTAGE" PICTURE "@!" OF oDlg PIXEL VALID AOMS112VT( C5_I_AGEND ) 

      nLin += 15

   	  @ nLin , nCol  Say 'Data de Entrega' OF oDlg PIXEL 
      @ nLin , nCol2 GET oDataEnt Var dDataEnt SIZE 40,09 PIXEL /*VALID NaoVazio(  )*/  OF oDlg PIXEL
      oDataEnt:bLostFocus := { || IIf(!Empty(AllTrim(DToS(dDataEnt))),(IIf(dDataEnt >= DATE(),dDataEnt,DATE()),oDataEnt:Refresh()),dDataEnt) }

      nLin += 15

   	  @ nLin , nCol  Say 'Filial de Carregamento' OF oDlg PIXEL 
      @ nLin , nCol2 MSGET oFilCar Var cFilCar SIZE 20,09 PIXEL F3 "SM0" OF oDlg PIXEL VALID AOMS112VF( @cFilCar,@cNomeCar,@oNomeCar,@cFilFat,@cNomeFat,@oNomeFat )  //QA_CHKFIL(cFilCar,@cFilCar) //VALID {||/*Vazio() .OR.*/ Pertence("SM0") }
      @ nLin , nCol2+20 MSGET oNomeCar Var cNomeCar SIZE 70,09 PIXEL OF oDlg PIXEL  When .F. 

      nLin += 15

      @ nLin , nCol  Say 'Filial de Faturamento' OF oDlg PIXEL 
      @ nLin , nCol2 MSGET oFilFat Var cFilFat SIZE 20,09 PIXEL F3 "SM0" OF oDlg PIXEL  VALID AOMS112VF( @cFilCar,@cNomeCar,@oNomeCar,@cFilFat,@cNomeFat,@oNomeFat )   //QA_CHKFIL(cFilFat,@cFilFat) //VALID {||/*Vazio() .OR.*/ Pertence("SM0") }
      @ nLin , nCol2+20 MSGET oNomeFat Var cNomeFat SIZE 70,09 PIXEL OF oDlg PIXEL  When .F. //QA_CHKFIL(cFilFat,@cFilFat) //VALID {||/*Vazio() .OR.*/ Pertence("SM0") }

      nLin += 15

      @ nLin , nCol  Say 'Operação' OF oDlg PIXEL 
      @ nLin , nCol2 MSGET oOper Var cOper SIZE 40,09 PIXEL F3 "ZB4" OF oDlg VALID (AOMS112VO(cOper))

      nLin += 20

    DEFINE SBUTTON FROM nLin,130  Type 1 ACTION IIf(AOMS112VM(),(oDlg:End(),AOMS112Y(C5_I_AGEND,dDataEnt,cFilCar,cFilFat,cOper)),Nil) ENABLE OF oDlg
   	DEFINE SBUTTON FROM nLin,166  Type 2 ACTION oDlg:End() ENABLE OF oDlg

   ACTIVATE MSDIALOG oDlg VALID ()
EndIf 

Return

/*
===============================================================================================================================
Programa----------: AOMS112Y
Autor-------------: Igor Melgaço
Data da Criacao---: 16/08/2024
Descrição---------: Altera os Marcados
Parametros--------: _cTipoAg,_dDtEnt
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS112Y(_cTipoAg,_dDtEnt,_cFilCar,_cFilFat,_cOper)

Local _nI := 0
Local aTpCar :={}
Local cTpCar := ""

Local _nposi := TRBF->(Recno())
Local _aPeds := {}
Local _acolec := {}
Local _aheaderec := {}
Local _nnh		:= 0
Local _nnm		:= 0
Private cfilfat := Space(30)
Private cfilcrg := Space(30)

If MV_PAR23 = 1 //SÓ REJEITADOS
   Return .F.
EndIf

If !Empty(AllTrim(_cTipoAg))

   aAdd(aTpCar,{'A','AGENDADA'})
   aAdd(aTpCar,{'I','IMEDIATA'})
   aAdd(aTpCar,{'O','AGENDADA P/ O.LOG.'})
   aAdd(aTpCar,{'M','AGENDADA C/MULTA'})

   nPos := aScan(aTpCar,{|x| x[1] == _cTipoAg}) 
   If nPos > 0
      cTpCar := aTpCar[nPos,2]
   Else
      cTpCar := 'AGUARD. AGENDA'
   EndIf
EndIf

For _nI := 1 to Len(aarr)
   If aarr[_nI,1] == cMarca

      If !Empty(AllTrim(_cTipoAg))
		   aarr[_nI,A112MAP("Tipo Entrega")] := cTpCar
      EndIf 
      
      If !Empty(AllTrim(DToS(_dDtEnt)))
         aarr[_nI,A112MAP("Dt Entrega")] := _dDtEnt
      EndIf

      If !Empty(_cFilCar)
         aarr[_nI,A112MAP("Filial Carregamento")] := SubStr(_cFilCar,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(_cFilCar,1,2),1,"") 
      EndIf

      If !Empty(_cFilFat)
         aarr[_nI,A112MAP("Filial Faturamento")] := SubStr(_cFilFat,1,2)+" - "+GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+SubStr(_cFilFat,1,2),1,"")
      EndIf

      If !Empty(_cOper)
         aarr[_nI,A112MAP("Tipo")] = _cOper + " - " + Posicione("ZB4",1,xFilial("ZB4")+_cOper,"ZB4_DESCRI")
      EndIf

   EndIf

Next
//Validação do Alex

	TRBF->( DBGoTop() )
   //Carrega pedidos selecionados
	While TRBF->(!Eof())
		// Somente pedidos selecionados pelo usuario
		If (TRBF->OK == cmarca .And. !linverte) .Or. (TRBF->OK != cmarca .And. linverte)
			aAdd(_aPeds,TRBF->(Recno()))
		EndIf

		TRBF->(DBSkip())

	EndDo

   //Retorna browse ao pedidos posicionado
	TRBF->(DBGoTo(_nposi))

	//Monta tela de confirmação

	//Monta aheader
	aAdd(_aheaderec,"Impresso")
	aAdd(_aheaderec,"Fil Car")
	aAdd(_aheaderec,"Fil Fat" )
	aAdd(_aheaderec,"Id Pedido" )
	aAdd(_aheaderec,"Cliente/Remessa")
	aAdd(_aheaderec,"Tipo Entrega")
	aAdd(_aheaderec,"Dt Emissão")
	aAdd(_aheaderec,"Dt Carga")
	aAdd(_aheaderec,"Trans Time")
	aAdd(_aheaderec,"Dt Entrega")
	aAdd(_aheaderec,"Tp Frete")
	aAdd(_aheaderec,"Tab Preço")
	aAdd(_aheaderec,"Cond Pgto")
	aAdd(_aheaderec,"Vendedor")
	aAdd(_aheaderec,"Mens NF")
	aAdd(_aheaderec,"Obs")

	//Monta acols
	For _nnh := 1 to Len(aarr)

		If aarr[_nnh][1] == cmarca

			aAdd(_acolec, {	 aarr[_nnh,A112MAP("Impresso")],;
				aarr[_nnh,A112MAP("Filial Faturamento") ],;
				aarr[_nnh,A112MAP("Filial Carregamento")],;
				aarr[_nnh,A112MAP("Id Pedido")],;
				aarr[_nnh,A112MAP("Cliente/Remessa")],;
				aarr[_nnh,A112MAP("Tipo Entrega")],;
				aarr[_nnh,A112MAP("Dt Emissão")],;
				aarr[_nnh,A112MAP("Dt Carga")],;
				aarr[_nnh,A112MAP("Trans Time")],;
				aarr[_nnh,A112MAP("Dt Entrega")],;
				aarr[_nnh,A112MAP("Tp Frete")],;
				aarr[_nnh,A112MAP("Tab Preço")],;
				aarr[_nnh,A112MAP("Cond Pgto")],;
				aarr[_nnh,A112MAP("Vendedor")],;
				aarr[_nnh,A112MAP("Mens NF")],;
				aarr[_nnh,A112MAP("Obs")]})
		EndIf

	Next

   cfilfat := _cFilFat
   cfilcrg := _cFilCar

	//_acolec2 := {}

	//Realiza alteração de pedidos
	For _nnm := 1 to Len(_aPeds)

		BEGIN TRANSACTION
			TRBF->(DBGoTo(_aPeds[_nnm]))

			_cfilul := TRBF->FILIAL
			_numul  := TRBF->NUMPED

			RecLock("TRBF",.F.)

         If !Empty(cfilcrg)
            TRBF->FILIAL := cfilcrg
         EndIf

         If !Empty(cfilfat)
            TRBF->FILPRO := cfilfat
         EndIf

         If !Empty(_cOper)
            TRBF->TIPO := _cOper
         EndIf

         If !Empty(AllTrim(_cTipoAg))
   		   TRBF->TPCAR := _cTipoAg
         EndIf 
         
         If !Empty(AllTrim(DToS(_dDtEnt)))
            TRBF->DT_ENTREG := DToC(_dDtEnt)
         EndIf         

			TRBF->(MSUnLock())

			_acolec[_nnm][1] := cfilfat
			_acolec[_nnm][2] := cfilcrg

			SZW->(DBSetOrder(1))
			If SZW->(DBSeek(SubStr(_cfilul,1,2)+_numul))

				If  !( AOMS112LO( SubStr(_cfilul,1,2), _numul,.F. ) )

					//aAdd(_acolec2,{_acolec[_nnm][1],_acolec[_nnm][2],_acolec[_nnm][3],_acolec[_nnm][4],"Pedido em uso!"})
					Disarmtransaction()

				Else

					SZW->(DBSeek(SubStr(_cfilul,1,2)+_numul))
					While SZW->ZW_FILIAL == SubStr(_cfilul,1,2) .And. AllTrim(SZW->ZW_IDPED) == AllTrim(_numul)

						RecLock("SZW",.F.)
                  If !Empty(AllTrim(cfilfat))
						   SZW->ZW_FILIAL := LEFT(cfilfat,2)
                  EndIf

                  If !Empty(AllTrim(cfilcrg))
						   SZW->ZW_FILPRO := LEFT(cfilcrg,2)
                  EndIf
                  
                  If !Empty(AllTrim(_cTipoAg))
            		   SZW->ZW_I_AGEND := _cTipoAg
                  EndIf 
                  
                 If !Empty(AllTrim(DToS(_dDtEnt)))
                     SZW->ZW_FECENT := _dDtEnt
                  EndIf

                  If !Empty(_cOper)
                     SZW->ZW_TIPO := _cOper
                  EndIf

						SZW->(MSUnLock())
						SZW->(DBSkip())

					EndDo

					AOMS112UN( SubStr(TRBF->FILIAL,1,2), _numul )
				EndIf

			Else
				Disarmtransaction()
				_acolec[_nnm][1] := TRBF->FILIAL
				_acolec[_nnm][2] := TRBF->FILPRO
			EndIf

		END TRANSACTION

	Next

   U_ITMsg("Alterações processadas com sucesso","Atenção",,1)
	//atualiza a tela
	FWMsgRun(,{|oproc| AOMS112arq(oproc)},"3 - Aguarde...","Atualizando tela...")

Return

/*
===============================================================================================================================
Programa----------: AOMS112VO
Autor-------------: Igor Melgaço
Data da Criacao---: 27/08/2024
Descrição---------: Altera os Marcados
Parametros--------: _cOper
Retorno-----------: _lReturn
===============================================================================================================================
*/
Static Function AOMS112VO(_cOper)

Local _lReturn := .T.

If !Empty(AllTrim(_cOper))
   DBSelectArea("ZB4")
   DBSetOrder(1)
   If DBSeek(xFilial("ZB4")+_cOper)
      _lReturn := .T.
   Else
      _lReturn := .F.
      U_ITMsg("Operação não valida!")
   EndIf
EndIf

Return _lReturn

/*
===============================================================================================================================
Programa----------: AOMS112VT
Autor-------------: Igor Melgaço
Data da Criacao---: 27/08/2024
Descrição---------: Valida Tipo de Entrega
Parametros--------: _cTipo
Retorno-----------: _lReturn
===============================================================================================================================
*/
Static Function AOMS112VT(_cTipo)

Local aCat := U_TipoEntrega() 
Local aDados := {}
Local _lReturn := .T.
Local i := 0

If !Empty(AllTrim(_cTipo))
   For i := 1 To Len(aCat)
      aAdd(aDados,StrToArray(aCat[i],"="))
   Next

   If aScan(aDados,{|x| x[1] == RTrim(_cTipo) }) > 0
      _lReturn := .T.
   Else
      _lReturn := .F.

      U_ITMsg("Tipo de Entrega não valido!")
   EndIf
EndIf

Return _lReturn


/*
===============================================================================================================================
Programa----------: AOMS112VF
Autor-------------: Igor Melgaço
Data da Criacao---: 27/08/2024
Descrição---------: Valida Filiais
Parametros--------: _cTipo
Retorno-----------: _lReturn
===============================================================================================================================
*/
Static Function AOMS112VF(cFilcrg,cNomeCrg,oNomeCrg,cFilfat,cNomeFat,oNomeFat)

Local lRet := .T.

If !Empty(cfilcrg)
	
	cNomeCrg := GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+LEFT(cfilcrg,2),1,"")
	If Empty(cNomeCrg)
		U_ITMsg("Filial de carregamento nao cadastrada",'Atenção',,1)
		Return .F.
	EndIf
Else
	cNomeCarg := ""
EndIf

If !Empty(cfilfat)

	cNomeFat := GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+LEFT(cfilfat,2),1,"")
	If Empty(cNomeFat)
		U_ITMsg("Filial de faturamento nao cadastrada",'Atenção',,1)
		Return .F.
	EndIf

	_cFilSalva:= cFilAnt
	cFilAnt   := LEFT(AllTrim(cfilfat),2)
	If AllTrim(SuperGetMV("IT_FATNF",.T.,"N")) == "N"
		U_ITMsg("Filial "+AllTrim(cfilfat)+" - " +AllTrim(cNomeFat)+" nao é troca nota de Faturamento (IT_FATNF)",'Atenção',,1)
		cFilAnt  := _cFilSalva
		Return .F.
	EndIf

	If !Empty(cfilcrg)
		cFilAnt:=LEFT(cfilcrg,2)
		If AllTrim(SuperGetMV("IT_PRONF",.T.,"N")) == "N"
			U_ITMsg("Filial "+AllTrim(cfilcrg)+" - " +AllTrim(cNomeCrg)+" nao é troca nota de Carregamento (IT_PRONF)",'Atenção',,1)
			cFilAnt  := _cFilSalva
			Return .F.
		EndIf
	EndIf

	cFilAnt  := _cFilSalva

	If lRet .And. !Empty(cfilcrg)                            //Fil Carregamento, Fil Faturamento
		lRet := U_AOM112Val( 'VAL_GRUPO' , left(cfilcrg,2) , left(cfilfat,2) )
	EndIf

Else
	cNomeFat := ""
EndIf

oNomeCrg:cText := cNomeCrg
oNomeFat:cText := cNomeFat
oNomeCrg:Refresh()
oNomeFat:Refresh()

Return lRet

/*
===============================================================================================================================
Programa----------: AOMS112VM
Autor-------------: Igor Melgaço
Data da Criacao---: 29/08/2024
Descrição---------: Valida se há seleção no Markbrwose
Parametros--------: _cTipo
Retorno-----------: _lReturn
===============================================================================================================================
*/
Static Function AOMS112VM()

Local _nI := 0 
Local lRet := .F.

For _nI := 1 to Len(aarr)
	If aarr[_nI,1] == cMarca
		lRet := .T.
		Exit
	EndIf
Next

If !lRet
	U_ITMsg("Não há registros marcados.",'Atenção!',"Selecione no minimo um pedido.",1)
EndIf

Return lRet
