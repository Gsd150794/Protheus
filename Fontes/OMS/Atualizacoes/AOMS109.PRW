/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
julio Paz     |10/09/2025| Chamado 51687. Ajustar as validações e mensagens da gravação do Pedido de Vendas para validar 
			  |			 | corretamente as permissões do usuário por Armazém.
Lucas Borges  |15/09/2025| Chamado 50617. Retirada manipulação do SX1
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "vkey.ch"

/*
===============================================================================================================================
Programa----------: AOMS109
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Central de pedidos de venda para logistica - Chamado 25428
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS109()

Private _alista := {}
Private _otemp := nil
Private _lMsgEmTela := .F.  //Para o mt410tok não mostrar mensagens em tela
Private _lOK_RDC := .T.
Private _aMsgVld    := {} // Para uso nas chamadas do aoms032
Private _aPVTransf  := {} // Grava o numero dos pedidos de vendas transferidos para outra filial.

_lMsgEmTela := .F.  //Para o mt410tok não mostrar mensagens em tela

AOMS109INI()

Return

/*
===============================================================================================================================
Programa----------: AOMS109INI
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Funcao que controla o processamento 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109INI()

Private cMarkado	:= GetMark()
Private lInverte	:= .F.

Private cPerg		:= 'AOMS109'

Private aCampos		:= {}
//==========================================
//Grava log de utilização da rotina
//==========================================
U_ITLOGACS()

Pergunte(cPerg,.F.) 

AOMS109PRC()

Return

/*
===============================================================================================================================
Programa----------: AOMS109PRC
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Função que Processa os pedidos de venda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109PRC()

Local _nControle := 0 
Local _nopc      := 1
Private cMarca   := GetMark()
Private aCampos  := {}
Private cPerg		:= 'AOMS109'

If Pergunte( cPerg , .T. )
       
	//================================================================================
	// Cria o arquivo Temporario para insercao dos dados selecionados.
	//================================================================================
	FWMsgRun( , {|oproc| _nControle := AOMS109ARQ(oproc, .T., .F.) }, "Aguarde!" , 'Lendo Dados dos pedidos...' )

	_nopc := AOMS109TRS()//Função que monta a tela para processar
	
EndIf
 
Return .T.

/*
===============================================================================================================================
Programa----------: AOMS109TRS
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Função que monta a tela para processar
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109TRS()

Local oPanel		:= Nil
Local oDlg1			:= Nil
Local nHeight		:= 0
Local nWidth		:= 0
Local aSize			:= {}
Local aBotoes		:= {}
Local aCoors		:= {}

Private nOpca		:= 0
Private cFiltro		:= "%" 
Private _aAreaCabec	:= {} 
Private _cFilPed	:= ""
Private _cNumPed	:= ""          
Private oMark		:= Nil
Private nQtdTit		:= 0
Private nPesTit	    := 0
Private nValTit     := 0
Private _nQtdPvSel  := 0
Private oQtda		:= Nil
Private oPesa		:= Nil
Private oValor      := Nil
Private oQtdPvSel   := Nil

//================================================================================
// Botoes da tela.
//================================================================================
aAdd( aBotoes , { "" , {|| AOMS109C(10) 	}	, "" , "Atualizar"		  } )
aAdd( aBotoes , { "" , {|| AOMS109C(01) 	}	, "" , "Pesquisar"		  } )
aAdd( aBotoes , { "" , {|| AOMS109C(05) 	}	, "" , "Filtro"           } )
aAdd( aBotoes , { "" , {|| AOMS109C(02) 	}	, "" , "Visualizar Pedido"} )
aAdd( aBotoes , { "" , {|| AOMS109C(03)		}	, "" , "Analisa Itens"	  } )
aAdd( aBotoes , { "" , {|| AOMS109C(04) 	}	, "" , "Legenda"          } )
aAdd( aBotoes , { "" , {|| AOMS109C(06) 	}	, "" , "Liberar"          } )
aAdd( aBotoes , { "" , {|| AOMS109C(07) 	}	, "" , "Estornar Lib"     } )
aAdd( aBotoes , { "" , {|| AOMS109C(11) 	}	, "" , "WF Liberação"     } )
aAdd( aBotoes , { "" , {|| AOMS109C(12) 	}	, "" , "Altera Produto"   } )
aAdd( aBotoes , { "" , {|| AOMS109C(13) 	}	, "" , "Manutenção"       } )
aAdd( aBotoes , { "" , {|| AOMS109C(08) 	}	, "" , "Cortar"           } )
aAdd( aBotoes , { "" , {|| AOMS109C(09) 	}	, "" , "Pre_Nota"         } ) 
aAdd( aBotoes , { "" , {|| AOMS109C(14) 	}	, "" , "Devolve TMS"      } )
aAdd( aBotoes , { "" , {|| AOMS109C(23) 	}	, "" , "Solicita Retorno PV TMS" } )
aAdd( aBotoes , { "" , {|| AOMS109C(15) 	}	, "" , "Exporta Excel"    } )
aAdd( aBotoes , { "" , {|| AOMS109C(16) 	}	, "" , "Desmembramento"    } )
aAdd( aBotoes , { "" , {|| AOMS109C(17) 	}	, "" , "Altera pedido"     } )
aAdd( aBotoes , { "" , {|| AOMS109C(18) 	}	, "" , "Definir Plan.Logístico"  } )
aAdd( aBotoes , { "" , {|| AOMS109C(19) 	}	, "" , "Retirar Plan.Logístico"  } )
aAdd( aBotoes , { "" , {|| AOMS109C(20) 	}	, "" , "Histórico pedido"    } )
aAdd( aBotoes , { "" , {|| AOMS109C(22) 	}	, "" , "Altera Armazem" } )

//================================================================================
// Faz o calculo automatico de dimensoes de objetos
//================================================================================
aSize := MSADVSIZE() 

//================================================================================
// Cria a tela para selecao dos pedidos
//================================================================================
_ctitulo := "CENTRAL DE PEDIDOS DE VENDAS PARA LOGISTICA"
		

 DEFINE MSDIALOG oDlg1 TITLE OemToAnsi(_ctitulo) From 0,0 To aSize[6],aSize[5] PIXEL

	oPanel       := TPanel():New(30,0,'',oDlg1,, .T., .T.,, ,315,20,.T.,.T. )
	@0.8,00.8 Say OemToAnsi("Quantidade:")						OF oPanel
	@0.8,0005 Say oQtda		VAR nQtdTit		Picture "@E 99999"	OF oPanel SIZE 60,8
	
	@0.8,0012 Say OemToAnsi("Peso:")						OF oPanel
	@0.8,0015 Say oPesa		VAR nPesTit		Picture "@E 999,999,999.99"	OF oPanel SIZE 60,8
	
	@0.8,0024 Say OemToAnsi("Valor:")						OF oPanel
	@0.8,0027 Say oValor	VAR nValTit		Picture "@E 999,999,999.99"	OF oPanel SIZE 60,8

    If FlatMode()
	
		aCoors	:= GetScreenRes()
		nHeight	:= aCoors[2]
		nWidth	:= aCoors[1]
		
	Else
	
		nHeight	:= 143
		nWidth	:= 315
		
	EndIf
	
	DBSelectArea("TRBF")
	TRBF->(DBGoTop()) 
	
	oMark					:= MsSelect():New( "TRBF" , "TRBF_OK" ,, aCampos , @lInverte , @cMarkado , { 35 , 1 , nHeight , nWidth } )
	oMark:bMark				:= {|| AOMS109INV( cMarkado , lInverte  ) }
	oMark:oBrowse:bAllMark	:= {|| FWMsgRun(,{ || AOMS109ALL( cMarkado) }, "Aguarde!" , 'Des / Marcando...' ) }
    oCol := oMark:oBrowse:aColumns[2]
    oCol:bData     := {|| U_AOMS109CL() }
    oMark:oBrowse:aColumns[2]:=oCol

	oDlg1:lMaximized:=.T.

ACTIVATE MSDIALOG oDlg1 ON INIT ( EnchoiceBar(oDlg1,{|| AOMS109C(02) },{|| nOpca := 2,oDlg1:End()},,aBotoes),;
                                  oPanel:Align:=CONTROL_ALIGN_TOP , oMark:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , oMark:oBrowse:Refresh())


Return nOpca

/*
===============================================================================================================================
Programa----------: AOMS109EXE
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Função que Processa os estornos da liberação
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109EXE(oproc)

Local _aLstPedV := {}
Local _nI 

Private lMsErroAuto	:= .F.                        

//=====================================================================
// Retorna um Array com grupos de produtos selecionados pelo usuário.
//=====================================================================
_aLstPedV := RetSelecPV() 

//==================================
// Se não tem registros já retorna
//==================================
If Empty(_aLstPedV)	 // Empty(_cNumPed)
   U_ITMsg("Nenhum registro selecionado","Atenção",,1)
   TRBF->(DBGoTop())
   Return
EndIf

//============================================================
// Faz o estorno de liberação por grupos de pedidos de vendas.
//============================================================	
Begin Transaction
   //================================================================================
   // Percorre os pedidos selecionados e monta o cabecalho e itens do pedido de venda
   //================================================================================
   _npv := 0
   _alista := {}
   SC5->(DBSetOrder(1))
   SA1->(DBSetOrder(1))
   SC9->(DBSetOrder(1))
	
   For _nI := 1 To Len(_aLstPedV)

	   SC5->(DBGoTo(_aLstPedV[_nI,3]))	
       
	   _cNumPed := SC5->C5_NUM

	   _npv++
		
	   //Atualiza régua
	   oproc:cCaption := ("Processando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	   ProcessMessages()
		
	   _aAreaCabec := SC5->( FWGetArea() )

	   //=======================================================================================================
	   // Caso outro usuario exclua, fature ou carregue o Pedido de Venda posteriormente ao usuario ter 
	   // filtrado os dados
	   //========================================================================================================
	   If Empty(SC5->C5_NOTA) .And. ( SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. Empty(SC9->C9_CARGA) .And. Empty(SC9->C9_NFISCAL) ) // ( SC5->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. 
          _nSalvaRecRDC:=0
  	      If SC5->C5_I_ENVRD = "S"
	         SC5->(RecLock("SC5",.F.))
		     SC5->C5_I_ENVRD := "N"
		     SC5->(MSUnLock())
             _nSalvaRecRDC:=SC5->(RECNO())
          EndIf

		  oproc:cCaption := ("Estornando liberação para PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
		  ProcessMessages()
            
  	      lMsErroAuto := .F.
          AOMS109R()//Estorna o bloqueio de estoque para o item de pedido de vendas

	      U_MOMS042P("N")

  		  If _nSalvaRecRDC <> 0
  		     SC5->(DBGoTo(_nSalvaRecRDC))
		     SC5->(RecLock("SC5",.F.))
		     SC5->C5_I_ENVRD := "S"               
			 SC5->( MSUnLock() ) 
          EndIf
		  						
		  If lMsErroAuto 
		     _cErro:="Erro ao estornar liberação do PV: "
	         _cErro+="["+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"Mata410.LOG")+"]"
		     aAdd(_alista,{_cNumPed,_cErro})
          Else
             aAdd(_alista,{_cNumPed, "LIBERACAO ESTORNADA COM SUCESSO"})
			 If _nSalvaRecRDC <> 0
			    If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms
			       oproc:cCaption := ("Enviando Status RDC do PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
				Else
                   oproc:cCaption := ("Enviando Status TMS Multi-Embarcador do PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]") 
				EndIf 

				ProcessMessages()
				U_ENVSITPV()//lret := startjob("U_ ENVSITPV",getenvserver(),.F.,,.F.)   //Envia interface de alteração de situação do pedido atual
             EndIf
          EndIf
	   Else
		  //Registra problema com pedido
		  If !SC5->( DBSeek( xFilial("SC5") + _cNumPed ) )
		     aAdd(_alista,{_cNumPed, "Pedido foi EXCLUIDO antes do processamento"})
		  ElseIf !Empty(SC5->C5_NOTA) 
		     aAdd(_alista,{_cNumPed, "Pedido foi FATURADO antes do processamento"})
  		  ElseIf SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. (!Empty(SC9->C9_CARGA) .Or. !Empty(SC9->C9_NFISCAL) )
  			 aAdd(_alista,{_cNumPed, "Pedido CARREGADO antes do processamento"})
		  ElseIf !SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM))
		     aAdd(_alista,{_cNumPed, "LIBERACAO ESTORNADA COM SUCESSO"})
	      EndIf
	   EndIf
    Next

End Transaction

If Len(_alista) > 0
	U_ITListBox( "Pedidos com liberação estornada" , {"Numero","Situacao"} , _alista , .T. , 1 )
EndIf

//Atualiza tela
FWMsgRun( , {|oproc| AOMS109ARQ(oproc) }, "Aguarde!" , 'Carregando dados...' )

Return

/*
===============================================================================================================================
Programa----------: AOMS109PSQ
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Funcao para pesquisa no arquivo temporario.
Parametros--------: oMark  - Objeto de dados
------------------: cAlias - Alias temporário
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109PSQ( oMark , cAlias )

Local oGet1		:= Nil
Local oDlg		:= Nil
Local cGet1		:= Space(40)
Local cComboBx1	:= ""
Local aComboBx1	:= { "Pedido" , "Cliente+Loja" , "Descricao Cliente" , "Descricao Rede" }
Local nOpca		:= 0
Local nI		:= 0

DEFINE MSDIALOG oDlg TITLE "Pesquisar" FROM 178,181 To 259,697 PIXEL

	@004,003 ComboBox	cComboBx1	Items aComboBx1 Size 213,010 OF oDlg PIXEL
	@020,003 MsGet		oGet1		Var cGet1		Size 212,009 OF oDlg PIXEL COLOR CLR_BLACK Picture "@!"
	
	DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( nOpca := 1 , oDlg:End() ) OF oDlg
	DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( nOpca := 0 , oDlg:End() ) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1

	For nI := 1 To Len(aComboBx1)
	
		If cComboBx1 == aComboBx1[nI]
		
			DBSelectArea("TRBF")
			TRBF->( DBSetOrder(2) )
			
			MsSeek( cGet1 , .T. )
			
			oMark:oBrowse:Refresh( .T. )
			TRBF->( DBSetOrder(1) )
			
		EndIf
		
	Next nI
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS109INV
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Rotina para inverter a marcacao do registro posicionado.
Parametros--------: cmarca - string de marcação do registro da tabela
					linverte - flag de inversão de registros
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109INV( cMarca , lInverte  )

Local lMarcado := IsMark( "TRBF_OK" , cMarca , lInverte )

If lMarcado
	nQtdTit++
	nPesTit	+= TRBF->C5_I_PESBR
	nValTit += TRBF->TRBF_VALOR
	_nQtdPvSel += 1 
Else
	nQtdTit--
	nPesTit	-= TRBF->C5_I_PESBR
	nValTit -= TRBF->TRBF_VALOR
	_nQtdPvSel -= 1 
EndIf

oQtda:Refresh()
oPesa:Refresh()
oValor:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS109ALL
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Rotina para inverter a marcacao de todos os registros.
Parametros--------: cMarca - string de marcação da tabela
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109ALL( cMarca  )

Local nReg     := TRBF->( Recno() )
Local lMarcado := .F.

DBSelectArea("TRBF")
TRBF->( DBGoTop() )

_nQtdPvSel := 0  

While TRBF->( !Eof() )
	
	lMarcado := IsMark( "TRBF_OK" , cMarca , lInverte )
	
	If lMarcado .Or. lInverte
		TRBF->TRBF_OK := Space(2)
		nQtdTit--
		nPesTit	-= TRBF->C5_I_PESBR
		nValTit -= TRBF->TRBF_VALOR
		
	Else
	    _nQtdPvSel += 1 
		TRBF->TRBF_OK := cMarca
		nQtdTit++
		nPesTit	+= TRBF->C5_I_PESBR
		nValTit += TRBF->TRBF_VALOR
   EndIf

   nQtdTit := IIf( nQtdTit < 0 , 0 , nQtdTit )
	
   TRBF->( DBSkip() )
EndDo

TRBF->( DBGoTo(nReg) )

oQtda:Refresh()
oPesa:Refresh()
oValor:Refresh()

oMark:oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: AOMS109ARQ
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Rotina para criação do arquivo temporário
Parametros--------: oproc - objeto da barra de processamento
					_lini - inicializa campos de data de necessidade
					_lcabec - inicializa campos de cabecalho
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function AOMS109ARQ(oproc,_lini,_lcabec)

Local aEstru		:= {}
Local cFiltro		:= "" 
Local _nNumReg		:= 0
Local _cSitEntrega   := "", _nNumDias
Local _dDataDia, _dDataEntrega

Default _lini := .F.
Default _lcabec := .T.

//GARANTE QUE O PERGUNTE ESTÁ CORRETO
Pergunte( cPerg , .F. )

//================================================================================
// Armazena no array aEstru a estrutura dos campos da tabela.
//================================================================================
aAdd( aEstru , { "TRBF_OK"		, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_FILIA"	, 'C' , 02 , 0 } )  
aAdd( aEstru , { "TRBF_NUM"		, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_OPER"    , 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_DTEMI"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_DTLIB"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_DTNES"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_DTENT"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_CODCL"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_LOJCL"	, 'C' , 04 , 0 } )
aAdd( aEstru , { "TRBF_DESCL"	, 'C' , 30 , 0 } )
aAdd( aEstru , { "TRBF_CODRE"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_DESCR"	, 'C' , 20 , 0 } )
aAdd( aEstru , { "TRBF_CODVE"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_DESVE"	, 'C' , 25 , 0 } )
aAdd( aEstru , { "C5_I_BLCRE"  	, 'C' , 01 , 0 } )
aAdd( aEstru , { "C5_I_BLPRC"  	, 'C' , 01 , 0 } )
aAdd( aEstru , { "C5_I_BLOQ"  	, 'C' , 01 , 0 } )
aAdd( aEstru , { "C5_I_BLOG"  	, 'C' , 01 , 0 } )
aAdd( aEstru , { "TRBF_UF"   	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_CEP"   	, 'C' , 15 , 0 } )
aAdd( aEstru , { "TRBF_MUN"   	, 'C' , 12 , 0 } )
aAdd( aEstru , { "TRBF_VALOR"	, 'N' , 14 , 2 } )
aAdd( aEstru , { "TRBF_FILCR"	, 'C' , 02 , 0 } ) 
aAdd( aEstru , { "TRBF_FILFT"	, 'C' , 02 , 0 } ) 
aAdd( aEstru , { "TRBF_AGEND"	, 'C' , 2  , 0 } )  
aAdd( aEstru , { "TRBF_STENT"	, 'C' , 20 , 0 } )  
aAdd( aEstru , { "C5_I_PEVIN"	, 'C' , 06 , 0 } ) 
aAdd( aEstru , { "C5_I_ENVRD"	, 'C' , 06 , 0 } ) 
aAdd( aEstru , { "C5_I_TRCNF"	, 'C' , 06 , 0 } ) 
aAdd( aEstru , { "QTDBLOQEST"	, 'N' , 15 , 5 } ) 
aAdd( aEstru , { "C5_LIBEROK"	, 'C' , 01 , 0 } ) 
aAdd( aEstru , { "C5_I_PESBR"	, 'N' , 15 , 5 } ) 
aAdd( aEstru , { "C5_I_PVREM"	, 'C' , 06 ,0  } ) 
aAdd( aEstru , { "TRBF_REGC5"	, 'N' , 12 ,0  } )  

//================================================================================
// Armazena no array aCampos o nome, picture e descricao dos campos
//================================================================================
aAdd( aCampos , { "TRBF_OK"		, "" , " "					, " "										} )
aAdd( aCampos , { "TRBF_OK"		, "" , " "					, " "										} )
aAdd( aCampos , { "TRBF_FILCR"	, "" , "Fil Car", "@!"	} )
aAdd( aCampos , { "TRBF_FILFT"	, "" , "Fil Fat" , "@!"	} )
aAdd( aCampos , { "TRBF_OPER"	, "" , "Tipo Ped" , "@!"	} )
aAdd( aCampos , { "TRBF_NUM"	, "" , "Pedido"				, PesqPict( "SC5" , "C5_NUM"	 )	 		} )
aAdd( aCampos , { "TRBF_AGEND"	, "" , "Tipo de Entrega"    , "@!"	} )  
aAdd( aCampos , { "TRBF_STENT"	, "" , "Sit. Entrega", "@!"	} )  
aAdd( aCampos , { "C5_I_PESBR"	, "" , "Peso"				, "@E 999,999.99"	 		} )
aAdd( aCampos , { "TRBF_DTNES"	, "" , "Data Necess"		, PesqPict( "SC5" , "C5_I_DTENT" )	  		} )
aAdd( aCampos , { "TRBF_DTENT"	, "" , "Data Entrega"		, PesqPict( "SC5" , "C5_I_DTENT" )	  		} )
aAdd( aCampos , { "TRBF_UF"	    , "" , "UF"					, PesqPict( "SA1" , "A1_EST"     )	  		} )
aAdd( aCampos , { "TRBF_MUN"    , "" , "Cidade"				, PesqPict( "SA1" , "A1_MUN"     )	  		} )
aAdd( aCampos , { "TRBF_CEP"	, "" , "CEP"				, PesqPict( "SA1" , "A1_CEP"     )	  		} )
aAdd( aCampos , { "TRBF_CODCL"	, "" , "Cliente"			, PesqPict( "SC5" , "C5_CLIENTE" )	  		} )
aAdd( aCampos , { "TRBF_LOJCL"	, "" , "Loja"				, PesqPict( "SC5" , "C5_LOJACLI" )	  		} )
aAdd( aCampos , { "TRBF_DESCL"	, "" , "Descricao Cliente"	, PesqPict( "SC5" , "C5_I_NOME"  )	  		} )
aAdd( aCampos , { "TRBF_CODRE"	, "" , "Rede"				, PesqPict( "SC5" , "C5_I_GRPVE" )	  		} )
aAdd( aCampos , { "TRBF_DESCR"	, "" , "Descricao Rede"		, PesqPict( "SC5" , "C5_I_NOMRD" )	  		} ) 
aAdd( aCampos , { "TRBF_CODVE"	, "" , "Vendedor"			, PesqPict( "SC5" , "C5_VEND1"   )	  		} )
aAdd( aCampos , { "TRBF_DESVE"	, "" , "Descricao Vendedor"	, PesqPict( "SC5" , "C5_I_V1NOM" )	  		} )
aAdd( aCampos , { "TRBF_OPER"	, "" , "Operação"			, PesqPict( "SC5" , "C5_I_OPER"	 )	 		} )
aAdd( aCampos , { "TRBF_DTEMI"	, "" , "Data Emissao"		, PesqPict( "SC5" , "C5_EMISSAO" )	  		} )
aAdd( aCampos , { "TRBF_DTLIB"	, "" , "Data Liberação"		, PesqPict( "SC5" , "C5_EMISSAO" )	  		} )
aAdd( aCampos , { "C5_I_PEVIN"	, "" , "PV Vinculado"       , "@!"	} )

aAdd( aCampos , { {||If(TRBF->C5_I_ENVRD="S","Sim","Não")},"","Envio TMS",""} )

aAdd( aCampos , { {||If(TRBF->C5_I_TRCNF="S","Sim","Não")},"","Troca Nota?",""} )
aAdd( aCampos , { "C5_I_PVREM"	, "" , "PV Remessa"       , "@!"	} )

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("TRBF") > 0
	oproc:cCaption := ("Apagando temporário...")
	ProcessMessages()
	TRBF->(DBCloseArea())
	If ValType(_otemp) == "O"
	   _otemp:Delete()
	EndIf
EndIf

oproc:cCaption := ("Criando arquivo temporário...")
ProcessMessages()
_otemp := FWTemporaryTable():New( "TRBF", aEstru )

oproc:cCaption := ("Criando indices do arquivo temporário...")
ProcessMessages()
_otemp:AddIndex( "CP", {"TRBF_CEP","TRBF_CODCL","TRBF_LOJCL"} )
_otemp:AddIndex( "NM", {"TRBF_NUM"} )

_otemp:Create()

//================================================================================
// Filtra Filiais
//================================================================================
cFiltro += " AND C5.C5_FILIAL	= '"+ xFilial("SC5") +"' " 

//================================================================================
// Emissao de - Ate
//================================================================================
If !Empty( MV_PAR01 ) .And. !Empty( MV_PAR02 )
		cFiltro += " AND C5.C5_I_DTNEC	BETWEEN '"+ DToS(MV_PAR01)	+"' AND '"+ DToS(MV_PAR02)	+"' "
EndIf
		
//================================================================================
// Liberacao de - Ate
//================================================================================
If !Empty( MV_PAR16 ) .And. !Empty( MV_PAR17 )

		cFiltro += "				AND  NVL(( SELECT C9_DATALIB FROM " + retsqlname("SC9") + " C93 "
		cFiltro += "                              WHERE C93.D_E_L_E_T_ = ' ' AND ROWNUM = 1 AND "
		cFiltro += "                                    C93.C9_FILIAL = C5.C5_FILIAL AND "
		cFiltro += "                                    C93.C9_PEDIDO = C5.C5_NUM ),'      ') BETWEEN '"+ DToS(MV_PAR16)	+"' AND '"+ DToS(MV_PAR17)	+"' "

EndIf
		
//================================================================================
// Data Entrega De - Ate
//================================================================================
If !Empty( MV_PAR03 ) .And. !Empty( MV_PAR04 )
	cFiltro += " AND C5.C5_I_DTENT	BETWEEN '"+ DToS(MV_PAR03)	+"' AND '"+ DToS(MV_PAR04)	+"' "
EndIf
	
//================================================================================
// Cliente De - Ate
//================================================================================
If !Empty( MV_PAR05 ) .And. !Empty( MV_PAR07 )
	cFiltro += " AND C5.C5_CLIENTE	BETWEEN '"+ MV_PAR05+"' AND '"+ MV_PAR07+"' "
EndIf

//================================================================================
// Loja De - Ate
//================================================================================
If !Empty( MV_PAR06 ) .And. !Empty( MV_PAR08 )
	cFiltro += " AND C5.C5_LOJACLI	BETWEEN '"+ MV_PAR06+"' AND '"+ MV_PAR08+"' "
EndIf

//================================================================================
// CEP De - Ate
//================================================================================
If !Empty( MV_PAR21 ) .And. !Empty( MV_PAR22 )
	cFiltro += " AND C5.C5_I_CEP	BETWEEN '"+ MV_PAR21+"' AND '"+ MV_PAR22+"' "
EndIf


//================================================================================
// Rede
//================================================================================
If !Empty( MV_PAR09 )                                                   
	If Len(AllTrim(MV_PAR09)) <= 6
		cFiltro += " AND C5.C5_I_GRPVE	= '" + AllTrim(MV_PAR09) + "' "
	Else
		cFiltro += " AND C5.C5_I_GRPVE	IN " + FormatIn( MV_PAR09 , ";" )
	EndIf
EndIf

//================================================================================
// Tipo de agenda
//================================================================================
If !Empty( MV_PAR18 )                                                   
	If Len(AllTrim(MV_PAR18)) <= 1
		cFiltro += " AND C5.C5_I_AGEND	= '" + AllTrim(MV_PAR18) + "' "
	Else
		cFiltro += " AND C5.C5_I_AGEND	IN " + FormatIn( MV_PAR18 , ";" )
	EndIf
EndIf


//================================================================================
// Pedido Funcionario
//================================================================================
If !Empty(MV_PAR19)
   If MV_PAR19 = 1
   	  cFiltro += " AND  C5.C5_I_OPER = '02' " 
   Else
      cFiltro += " AND  C5.C5_I_OPER <> '02' " 
   EndIf
EndIf


//================================================================================
// Estado
//================================================================================
If !Empty( MV_PAR10 )     
	If Len(AllTrim(MV_PAR10)) <= 2
		cFiltro  += " AND C5.C5_I_EST = '"+ AllTrim(MV_PAR10) + "' "
	Else
		cFiltro  += " AND C5.C5_I_EST IN "+ FormatIn( MV_PAR10 , ";" )
	EndIf
EndIf

//================================================================================
// Municipio
//================================================================================
If !Empty( MV_PAR11 )             
	If Len(AllTrim(MV_PAR11)) <= 6
		cFiltro  += " AND C5.C5_I_CMUN = '"+ AllTrim(MV_PAR11) + "' "
	Else
		cFiltro  += " AND C5.C5_I_CMUN	IN "+ FormatIn( MV_PAR11 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra Coordenador
//================================================================================
If !Empty( MV_PAR12 )             
	If Len(AllTrim(MV_PAR12)) <= 6
		cFiltro += " AND C5.C5_VEND2 = '"+ AllTrim(MV_PAR12) + "' "
	Else
		cFiltro += " AND C5.C5_VEND2 IN "+ FormatIn( MV_PAR12 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra exclui Coordenador
//================================================================================
If !Empty( MV_PAR23 )             
	If Len(AllTrim(MV_PAR23)) <= 6
		cFiltro += " AND C5.C5_VEND2 != '"+ AllTrim(MV_PAR23) + "' "
	Else
		cFiltro += " AND C5.C5_VEND2 NOT IN "+ FormatIn( MV_PAR23 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra Vendedor
//================================================================================
If !Empty( MV_PAR13 )      
	If Len(AllTrim(MV_PAR13)) <= 6
		cFiltro += " AND C5.C5_VEND1 = '"+ AllTrim(MV_PAR13) + "' "
	Else
		cFiltro += " AND C5.C5_VEND1 IN "+ FormatIn( MV_PAR13 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra Supervisor
//================================================================================
If !Empty( MV_PAR24 )      
	If Len(AllTrim(MV_PAR24)) <= 6
		cFiltro += " AND C5.C5_VEND4 = '"+ AllTrim(MV_PAR24) + "' "
	Else
		cFiltro += " AND C5.C5_VEND4 IN "+ FormatIn( MV_PAR24 , ";" )
	EndIf
EndIf


//================================================================================
// Filtra Produto
//================================================================================
If !Empty( MV_PAR14 )

	cFiltro += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SC6")+ " C6 "
	cFiltro += " WHERE C6.D_E_L_E_T_ = ' ' AND C6.C6_FILIAL = C5.C5_FILIAL AND C6.C6_NUM = C5.C5_NUM "
	cFiltro += " AND C6.C6_PRODUTO	IN "+ FormatIn( MV_PAR14 , ";" ) + " )" 	
	
EndIf

//================================================================================
// Filtra Produto
//================================================================================
If !Empty( MV_PAR20 ) .Or. 	MV_PAR30 > 0 .Or. MV_PAR31 > 0

	cFiltro += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SC6")+ " C6 "
	cFiltro += " WHERE C6.D_E_L_E_T_ = ' ' AND C6.C6_FILIAL = C5.C5_FILIAL AND C6.C6_NUM = C5.C5_NUM "
	If !Empty( MV_PAR20 )
		cFiltro += " AND C6.C6_LOCAL IN "+ FormatIn( MV_PAR20 , ";" ) + " )" 	
	EndIf
	If  MV_PAR30 > 0 .Or. MV_PAR31 > 0
		cFiltro += " AND (C6.C6_PRCVEN - (C6.C6_PRCVEN * C6.C6_I_PDESC)/100) BETWEEN "+ Str(MV_PAR30) + " AND "+ Str(MV_PAR31) + ") "   
	EndIf
EndIf

//================================================================================
// Filtra Classe de cliente
//================================================================================
If MV_PAR25 <> 4
   cFiltro += " AND (SELECT A1_I_CLABC FROM "+ RETSQLNAME('SA1') +" SA1 "
   cFiltro += " WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_COD = C5.C5_CLIENTE AND SA1.A1_LOJA = C5.C5_LOJACLI "
   cFiltro += " AND ROWNUM = 1) = '"+Str(MV_PAR25,1)+"' "
EndIf

//================================================================================
// Filtra Pedidos de Vendas pela data de Emissão.
//================================================================================
If !Empty(MV_PAR27)
   cFiltro += " AND C5_EMISSAO >= '" + DToS(MV_PAR27) + "' "
EndIf

If !Empty(MV_PAR28)
   cFiltro += " AND C5_EMISSAO <= '" + DToS(MV_PAR28) + "' "
EndIf

//================================================================================
// Filtra Gerente
//================================================================================
If !Empty( MV_PAR29 )
	cFiltro += " AND C5.C5_VEND3 = '"+ AllTrim(MV_PAR29) + "' "	
EndIf

//================================================================================
// Filtra Pedidos de Vendas Normais. Apenas os Pedidos de Tipo Normal podem ser
// alterados.
//================================================================================
cFiltro += " AND C5.C5_TIPO = 'N' "

//================================================================================
// Filtra Pedidos de Vendas Integrados ou não para o sistema TMS. 
//================================================================================
If MV_PAR32 == 1 // Sim
   cFiltro += " AND C5.C5_I_ENVRD = 'S' "
ElseIf MV_PAR32 == 2 // Não
   cFiltro += " AND (C5.C5_I_ENVRD = 'N' OR C5.C5_I_ENVRD = ' ') "
EndIf 

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("QRYPED") > 0
	QRYPED->( DBCloseArea() )
EndIf

//================================================================================
// Query para selecao dos dados DOS PEDIDOS
//================================================================================
_cQuery := "	SELECT		C5.C5_FILIAL	, C5.C5_NUM		, C5.C5_CLIENTE	, C5.C5_LOJACLI,C5_I_BLCRE, "
_cQuery += "				C5.C5_I_GRPVE	, C5.C5_I_NOMRD	, C5.C5_VEND1	, C5.C5_EMISSAO, C5.R_E_C_N_O_ C5REC,
_cQuery += "				C5.C5_I_PEDGE	, C5.C5_I_NPALE	, C5_I_PVREM    , C5_I_ENVRD, C5_I_DTNEC,C5_I_BLPRC,
_cQuery += "				C5.C5_I_FILFT	, C5.C5_I_FLFNC , C5_I_AGEND    , C5_I_PEVIN, C5_I_PESBR,C5_I_BLOQ, 
_cQuery += "				C5_I_TRCNF      , C5_I_PDFT     , C5_I_OPER     , C5_I_DTENT, C5_LIBEROK,C5_I_CEP,
_cQuery += "				C5.C5_I_NOME,C5.C5_I_EST,C5.C5_I_V1NOM,C5.C5_I_MUN,C5.C5_I_BLOG,C5_I_PVREM,

_cQuery += "				NVL(( SELECT C9_DATALIB FROM " + retsqlname("SC9") + " C93 "
_cQuery += "                              WHERE C93.D_E_L_E_T_ = ' ' AND ROWNUM = 1 AND "
_cQuery += "                                    C93.C9_FILIAL = C5.C5_FILIAL AND "
_cQuery += "                                    C93.C9_PEDIDO = C5.C5_NUM ),'      ') DTLIB, "
				
_cQuery += "	            ( SELECT SUM(C9_QTDLIB) FROM " + retsqlname("SC9") + " C9
_cQuery += "                              WHERE C9.D_E_L_E_T_ = ' ' AND  C9_BLEST <> ' ' AND 
_cQuery += "                                    C9.C9_FILIAL = C5.C5_FILIAL AND 
_cQuery += "                                    C9.C9_PEDIDO = C5.C5_NUM ) QTDBLOQEST
_cQuery += "	FROM		" + retsqlname("SC5") + " C5
_cQuery += "	WHERE			C5.D_E_L_E_T_ = ' ' 
_cQuery += "				AND C5.C5_NOTA    = ' '
_cQuery += "                AND ( C5.C5_I_TRCNF <> 'S' OR (C5.C5_I_FLFNC = C5.C5_FILIAL))
_cQuery += "				AND C5.C5_I_OPER    <> '50' AND  C5.C5_I_OPER    <> '51' "
_cQuery += "                AND (SELECT A1.A1_MSBLQL FROM " + retsqlname("SA1") + " A1 WHERE A1.D_E_L_E_T_ = ' ' AND A1.A1_COD = C5.C5_CLIENTE AND A1.A1_LOJA = C5.C5_LOJACLI) <> '1' "
_cQuery += "				AND  NVL(( SELECT C9_CARGA FROM " + retsqlname("SC9") + " C92
_cQuery += "                              WHERE C92.D_E_L_E_T_ = ' ' AND ROWNUM = 1 AND
_cQuery += "                                    C92.C9_FILIAL = C5.C5_FILIAL AND 
_cQuery += "                                    C92.C9_PEDIDO = C5.C5_NUM ),'      ') = '      '
_cQuery += cFiltro
	
_cQuery += "	ORDER BY	C5_FILIAL,C5_NUM

oproc:cCaption := ("Carregando query de pedidos...")
ProcessMessages()

//TCQUERY _cQuery NEW ALIAS "QRYPED"
MPSysOpenQuery( _cQuery , "QRYPED")

DBSelectArea("QRYPED")

oproc:cCaption := ("Contando os pedidos...")
ProcessMessages()

nQtdTit := 0
COUNT To nQtdTit
QRYPED->(DBGoTop())
_npv:=1
MV_PAR15 := AllTrim(MV_PAR15)


While QRYPED->(!Eof())
	lOk := .F.
	//Atualiza régua
	oproc:cCaption := ("Processando pedido de vendas... ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	ProcessMessages()
	_npv++

	//inicio
    If !Empty(MV_PAR15) 

		If ("P" $ MV_PAR15) //Pedidos com bloqueio de preço
			If (QRYPED->C5_I_BLPRC $ "BR") 
				lOk:= .T.
			EndIf 
       	EndIf
     
    	If ("B" $ MV_PAR15) //Pedidos com bloqueio de bonificação
   
			If (QRYPED->C5_I_BLOQ $ "BR" )
				lOk:= .T.
			EndIf
			
	    EndIf
    
    	If  ("C" $ MV_PAR15) //Pedidos com bloqueio de crédito
   
			If (QRYPED->C5_I_BLCRE $ "BR")
				lOk:= .T.
			EndIf
		
    	EndIf
    
    
		If  ("E" $ MV_PAR15) //Pedidos com bloqueio de estoque
	
			If QRYPED->QTDBLOQEST > 0
				lOk:= .T.
			EndIf
		 
		EndIf
		
		If ("L" $ MV_PAR15) //Pedidos com liberação ok de estoque
	
			If (QRYPED->C5_LIBEROK = "S" .And. QRYPED->QTDBLOQEST = 0)
				lOk:= .T.			
			EndIf
		
		EndIf
		
		If   ("O" $ MV_PAR15) //Pedidos em carteira
	
			If QRYPED->C5_LIBEROK = " " .And. QRYPED->QTDBLOQEST = 0 .AND.;
					!(QRYPED->C5_I_BLCRE = "B" .Or. QRYPED->C5_I_BLCRE = "R") .AND.;
					!(QRYPED->C5_I_BLPRC = "B" .Or. QRYPED->C5_I_BLPRC = "R") .AND.;
					!(QRYPED->C5_I_BLOQ = "B" .Or. QRYPED->C5_I_BLOQ = "R")
				lOk:= .T.					
			EndIf
			
		EndIf
		If !lOk
			QRYPED->( DBSkip() )
			Loop
		EndIf
	EndIf

    //======================================================
    // Filtro por tipo de carga.
    //======================================================
    If ! U_AOMS109U(QRYPED->C5_FILIAL, QRYPED->C5_NUM)
       QRYPED->( DBSkip() )
	   Loop
	EndIf
	
	
	_nNumReg++
    
    _nvalsc5 := 0
    
    If _lini .Or. Empty(QRYPED->C5_I_DTNEC)
    
    	aheader := {}
    	acols := {}
    	aAdd(aheader,{1,"C6_ITEM"})
    	aAdd(aheader,{2,"C6_PRODUTO"})
    	aAdd(aheader,{3,"C6_LOCAL"})

    	SC6->(DBSetOrder(1))
    	SC6->(DBSeek(QRYPED->C5_FILIAL+QRYPED->C5_NUM))
		
    	While SC6->(!Eof()) .And. QRYPED->C5_FILIAL == SC6->C6_FILIAL .And. QRYPED->C5_NUM == SC6->C6_NUM
    		aAdd(acols,{SC6->C6_ITEM,SC6->C6_PRODUTO,SC6->C6_LOCAL})
    		_nvalsc5 += SC6->C6_QTDVEN * SC6->C6_PRCVEN
    		SC6->(DBSkip())
    	EndDo
	
    	_dneces := SToD(QRYPED->C5_I_DTENT) - (U_OMSVLDENT(SToD(QRYPED->C5_I_DTENT),QRYPED->C5_CLIENTE,QRYPED->C5_LOJACLI,QRYPED->C5_I_FILFT,QRYPED->C5_NUM,1))
	
    	SC5->(DBGoTo(QRYPED->C5REC))
    	If _dneces != SC5->C5_I_DTNEC .And. SC5->(MsRLock(SC5->(RECNO())))
    		SC5->C5_I_DTNEC := _dneces
    		SC5->(MSUnLock())
     	EndIf
     
    Else
    
    	_dneces := SToD(QRYPED->C5_I_DTNEC)
     	SC6->(DBSetOrder(1))
    	SC6->(DBSeek(QRYPED->C5_FILIAL+QRYPED->C5_NUM))
   	   	While SC6->(!Eof()) .And. QRYPED->C5_FILIAL == SC6->C6_FILIAL .And. QRYPED->C5_NUM == SC6->C6_NUM
    		_nvalsc5 += SC6->C6_QTDVEN * SC6->C6_PRCVEN
    		SC6->(DBSkip())
    	EndDo
     
    EndIf

	_cSitEntrega:= U_TipoEntrega(QRYPED->C5_I_AGEND)
    If (QRYPED->C5_I_AGEND == "A" .Or. QRYPED->C5_I_AGEND == "M")
	   
	   _dDataDia := Date()
	   _dDataEntrega := SToD(QRYPED->C5_I_DTENT)
	   _nNumDias := _dDataEntrega - _dDataDia
       
	   If _nNumDias <= 0 
          _cSitEntrega := "Perdeu agenda"
       ElseIf (_nNumDias > 1 .And. _nNumDias <= 7 ) 
          _cSitEntrega := "Semana 1"
       ElseIf _nNumDias > 7 .And. _nNumDias <= 14 
          _cSitEntrega := "Semana 2"
       ElseIf _nNumDias > 14 .And. _nNumDias <= 21  
          _cSitEntrega := "Semana 3"
       ElseIf _nNumDias > 21 
          _cSitEntrega := "Posterior"  
       EndIf

    EndIf 

    //RecLock("TRBF",.T.)
	TRBF->(DBAPPEND())
    TRBF->TRBF_FILIA	:= QRYPED->C5_FILIAL
    TRBF->TRBF_NUM		:= QRYPED->C5_NUM
    TRBF->TRBF_OPER     := QRYPED->C5_I_OPER
    TRBF->TRBF_DTEMI	:= SToD(QRYPED->C5_EMISSAO)
    TRBF->TRBF_DTENT	:= SToD(QRYPED->C5_I_DTENT)
    TRBF->TRBF_DTLIB	:= SToD(QRYPED->DTLIB)
    TRBF->TRBF_CODCL	:= QRYPED->C5_CLIENTE
    TRBF->TRBF_LOJCL	:= QRYPED->C5_LOJACLI
    TRBF->TRBF_DESCL	:= QRYPED->C5_I_NOME
    TRBF->TRBF_UF   	:= QRYPED->C5_I_EST
    TRBF->TRBF_CEP   	:= QRYPED->C5_I_CEP
    TRBF->TRBF_CODRE	:= QRYPED->C5_I_GRPVE
    TRBF->TRBF_DESCR	:= QRYPED->C5_I_NOMRD
    TRBF->TRBF_CODVE	:= QRYPED->C5_VEND1
    TRBF->TRBF_DESVE	:= QRYPED->C5_I_V1NOM
    TRBF->TRBF_FILCR    := IIf(Empty(QRYPED->C5_I_FLFNC),QRYPED->C5_FILIAL,QRYPED->C5_I_FLFNC)
    TRBF->TRBF_FILFT 	:= IIf(Empty(QRYPED->C5_I_FILFT),QRYPED->C5_FILIAL,QRYPED->C5_I_FILFT)
    TRBF->TRBF_AGEND 	:= QRYPED->C5_I_AGEND 
	TRBF->TRBF_STENT    := _cSitEntrega       
    TRBF->C5_I_PEVIN 	:= QRYPED->C5_I_PEVIN
    TRBF->C5_I_ENVRD 	:= QRYPED->C5_I_ENVRD
    TRBF->C5_I_TRCNF 	:= QRYPED->C5_I_TRCNF
    TRBF->QTDBLOQEST 	:= QRYPED->QTDBLOQEST
    TRBF->C5_LIBEROK 	:= QRYPED->C5_LIBEROK
    TRBF->C5_I_PESBR 	:= QRYPED->C5_I_PESBR
    TRBF->C5_I_BLCRE 	:= QRYPED->C5_I_BLCRE
    TRBF->C5_I_BLPRC 	:= QRYPED->C5_I_BLPRC
    TRBF->C5_I_BLOQ 	:= QRYPED->C5_I_BLOQ
	TRBF->C5_I_BLOG 	:= QRYPED->C5_I_BLOG
    TRBF->TRBF_MUN	 	:= QRYPED->C5_I_MUN
    TRBF->TRBF_DTNES    := _dneces
    TRBF->TRBF_VALOR    := _nvalsc5
	TRBF->C5_I_PVREM    := QRYPED->C5_I_PVREM
	TRBF->TRBF_REGC5    := QRYPED->C5REC   
	
    QRYPED->( DBSkip() )
	
EndDo

QRYPED->( DBCloseArea())

TRBF->(DBGoTop())

If _lcabec  //Inicializa cabecalho

	nQtdTit := 0
	nPesTit	:= 0
	nValTit := 0

	oQtda:Refresh()
	oPesa:Refresh()
	oValor:Refresh()
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS109PPV
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Função para visualizar Pedidos de Vendas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109PPV()   
                              
DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( TRBF->( TRBF_FILIA + TRBF_NUM ) ) )
	MatA410(Nil, Nil, Nil, Nil, "A410Visual") 
EndIf

Return

/*
===============================================================================================================================
Função------------: AOMS109R
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Estorna o bloqueio de estoque para o item de pedido de vendas.
Parametros--------: Nenhum
Retorno-----------: True or False
===============================================================================================================================
*/
Static Function AOMS109R()

Local _lRet := .T.
Local _aSaveArea := FWGetArea()

SC6->(DBSetOrder(1))
SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

//Se tiver liberação válida para todos os itens desfaz liberação

While !(SC6->(Eof())) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->C5_FILIAL+SC5->C5_NUM
	SC9->(DBSetOrder(1))
	If (SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM)))
		SC9->(_lRet:=A460Estorna()) // estorna a liberação
		If !_lRet
			aAdd(_alista,{SC6->C6_NUM+" + "+SC6->C6_ITEM, "Pedido + Item teve problemas na liberação"})
			lMsErroAuto:=.T.
		EndIf
	EndIf
	SC6->(DBSkip())
EndDo

SC9->(DBSetOrder(1))
If !SC9->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
   SC5->(RecLock("SC5",.F.))
   SC5->C5_LIBEROK := "  "
   SC5->C5_I_STATU := "01"
   SC5->C5_I_BLOG  := "N"
   SC5->(MSUnLock())
Else
   aAdd(_alista,{_cNumPed, "Problemas no Estoque de Liberacao (Ainda tem SC9)"})
EndIf

MSUnLockAll()
SC6->(MSUnLockALL())
SC6->(MSUnLock())
SB2->(MSUnLockALL())
SB2->(MSUnLock())
SC5->(MSUnLockALL())

FWRestArea(_aSaveArea)

Return lMsErroAuto

/*
===============================================================================================================================
Programa----------: AOMS109AI
Autor-------------: Alex Wallauer
Data da Criacao---: 08/08/2018
Descrição---------: Analisa itens
Parametros--------: _cped - Numero do pedido
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109AI(cPED)

Local _cnomefil	:= ""
Local _ccodcomp	:= ""

Private oAzul 		:= LoadBitmap( GetResources(), "BR_AZUL" )
Private oAmarelo    := LoadBitmap( GetResources(), "BR_AMARELO" )
Private oVerde    := LoadBitmap( GetResources(), "BR_VERDE" )
Private aSize     := {}
Private aLigacoes := {}
Private aCC       := {}

//Se não tem registros já retorna
If 	Empty(cPED)

	U_ITMsg("Nenhum registro selecionado","Atenção",,1)
	TRBF->(DBGoTop())
	Return
	
EndIf


AOMS109S() //Função utilizada para mostrar as configurações de tela do usuário

SC6->( DBSetOrder(1) )
SC6->( DBSeek(xFilial("SC6")+AllTrim(CPED),.T.) )

SC5->( DBSetOrder(1) )
SC5->( DBSeek(xFilial("SC5")+AllTrim(CPED)) )

nQtd2UM := 0
SC9->(DBSetOrder(1))
SB1->(DBSetOrder(1))

While SC6->(!Eof()) .And. SC6->C6_NUM == AllTrim(CPED)


    SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
 	nFator  := SB1->B1_CONV
	cTipConv:= SB1->B1_TIPCONV
	nNewFat := SB1->B1_I_FATCO
	
	nFator := (If(nFator == 0, nNewFat, nFator))
	If cTipConv == 'D'
		nQtd2UM := SC6->C6_QTDVEN/nFator
	ElseIf cTipConv == 'M'
	 	nQtd2UM := SC6->C6_QTDVEN*nFator
	EndIf
	 
    _cBloq:=" "
    If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM)) 
     	If !Empty(SC9->C9_BLEST)  // verifica estoque se não tem liberação válida ainda	
     		_cBloq:="B"
     	EndIf
    Else
    	_cbloq := "N"  //não tem liberação
    EndIf

    If SB2->(DBSeek(xFilial("SB2") + SC6->C6_PRODUTO + SC6->C6_LOCAL))
          _nSaldo:=(SB2->B2_QATU - SB2->B2_QEMP - SB2->B2_QEMPN - SB2->B2_RESERVA - SB2->B2_QACLASS)
    Else
	   _nSaldo := 0
	EndIf   
    
	aAdd(aCC, {	" ",;//01
					SC6->C6_ITEM,;//02
					AllTrim(SC6->C6_PRODUTO),;//03
					AllTrim(SB1->B1_DESC),;//04
					AllTrim(SC6->C6_UM),;//05
					Transform(SC6->C6_QTDVEN,"@E 999,999,999.99999"),;//06
					SC6->C6_LOCAL,;//17
					Transform(_nSaldo,"@E 999,999,999,999,999.99999"),;//08
					GetAdvFVal("SB1","B1_SEGUM",xFilial("SB1")+SC6->C6_PRODUTO,1,""),;//09
					Transform(nQtd2UM,"@E 999,999,999.99999"),;//10
					Transform(SC6->C6_PRCVEN, "@E 9,999.99"),;//11
					Transform(SC6->C6_QTDVEN*SC6->C6_PRCVEN, "@E 999,999.99"),;//12
					_cBloq}) //13
/*											"Item",;
											"Produto",;
											"Descriçâo",;
											"1ªUM",;
											"Qtd 1ªUM",;
											"Armazem",;
											"Saldo Armaz",;
											"2ªUM",;
											"Qtd 2ªUM",;
											"Prc Vend",;
											"Total";*/					
	SC6->( DBSkip() )
	
End

DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
SC5->( DBSeek(xFilial("SC5")+CPED) )

aLigacoes := aSort(aCC,,,{|x,y|x[2]<y[2]})

If Len(aLigacoes) <= 0

	Help(" ",1,"SEMDADOS" )
	Return(.F.)
	
EndIf
lClos := .F.
DEFINE MSDIALOG _oDlgHist FROM 1,000 To aSize[6],aSize[5] TITLE "Itens do Pedido " + CPED  PIXEL

_cnomefil := AllTrim(SC5->C5_FILIAL) + " / " + FWFilialName(cEmpAnt,SC5->C5_FILIAL)
If Empty(SC5->C5_I_FILFT)
	_cnomefat := AllTrim(SC5->C5_FILIAL) + " / " + FWFilialName(cEmpAnt,SC5->C5_FILIAL)
Else
	_cnomefat := AllTrim(SC5->C5_I_FILFT) + " / " + FWFilialName(cEmpAnt,SC5->C5_I_FILFT)
EndIf
If SC5->C5_I_TRCNF = "S"
	_cnomefat := "Troca Nota - " + _cnomefat
Else
	_cnomefat := "Faturamento Direto - " + _cnomefat
EndIf

@ 005,005 Say "Pedido:" 
@ 005,040 Get CPED        Picture "@!"  SIZE 050,10 when .F. 
@ 005,090 Get _cnomefil   Picture "@!"  SIZE 200,10 when .F. 

@ 005,330 Say "Filial Faturamento:" 
@ 005,375 Get _cnomefat   Picture "@!"  SIZE 200,10 when .F. 

@ 020,005 Say "Cliente:"

_ccodcomp := AllTrim(SC5->C5_CLIENTE) + " / " + AllTrim(SC5->C5_LOJACLI)

@ 020,040 Get _ccodcomp  Picture "@!"  SIZE 050,10 when .F. 
@ 020,090 Get AllTrim(GetAdvFval("SA1","A1_NOME",xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,1,"")) Picture "@!"  SIZE 200,10 when .F. 

@ 020,330 Say "Loja cliente: " 
@ 020,375 Get AllTrim(GetAdvFval("SA1","A1_NREDUZ",xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,1,"")) Picture "@!"  SIZE 200,10 when .F.

@ 035,005 Say "Vendedor:"
@ 035,040 Get SC5->C5_VEND1 Picture "@!"  SIZE 050,10 when .F. 
@ 035,090 Get AllTrim(GetAdvFval("SA3","A3_NOME",xFilial("SA3")+SC5->C5_VEND1,1,"")) Picture "@!"  SIZE 200,10 when .F.  

@ 050,005 Say "Coordenador:"
@ 050,040 Get SC5->C5_VEND2 Picture "@!"  SIZE 050,10 when .F. 
@ 050,090 Get AllTrim(GetAdvFval("SA3","A3_NOME",xFilial("SA3")+SC5->C5_VEND2,1,"")) Picture "@!"  SIZE 200,10 when .F.

@ 065,005 Say "Gerente:"
@ 065,040 Get SC5->C5_VEND3 Picture "@!"  SIZE 050,10 when .F. 
@ 065,090 Get AllTrim(GetAdvFval("SA3","A3_NOME",xFilial("SA3")+SC5->C5_VEND3,1,"")) Picture "@!"  SIZE 200,10 when .F.

@080,05 LISTBOX oLbx FIELDS HEADER 	" ",;
											"Item",;
											"Produto",;
											"Descriçâo",;
											"1ªUM",;
											"Qtd 1ªUM",;
											"Armazem",;
											"Saldo Armazem",;
											"2ªUM",;
											"Qtd 2ªUM",;
											"Prc Vend",;
											"Total";
SIZE aSize[3],aSize[4]-110 OF _oDlgHist PIXEL 

oLbx:SetArray(aLigacoes)
oLbx:bLine:={||{If(aLigacoes[oLbx:nAt,13]='N',oVerde,If(aLigacoes[oLbx:nAt,13]='B',oAzul,oAmarelo)),;
						aLigacoes[oLbx:nAt,2],;
						aLigacoes[oLbx:nAt,3],;
						aLigacoes[oLbx:nAt,4],;
						aLigacoes[oLbx:nAt,5],;
						aLigacoes[oLbx:nAt,6],;
						aLigacoes[oLbx:nAt,7],;
						aLigacoes[oLbx:nAt,8],;
						aLigacoes[oLbx:nAt,9],;
						aLigacoes[oLbx:nAt,10],;
						aLigacoes[oLbx:nAt,11],;
						aLigacoes[oLbx:nAt,12]}}

oLbx:Refresh()
oLbx:SetFocus(.T.)

@ aSize[4]-20,aSize[3]-130 	Button "&Opcoes"	Size 037,012 action (FWMsgRun(,{ || AOMS109O()},"Aguarde...","Carregando tela de opções de armazéns..."))
@ aSize[4]-20,aSize[3]-65 	Button "&Sair" 		Size 037,012 action (lClos := .F.,_oDlgHist:end())

ACTIVATE MSDIALOG _oDlgHist CENTER 

Return

/*
===============================================================================================================================
Programa----------: AOMS109S
Autor-------------: Alex Wallauer
Data da Criacao---: 08/08/2018
Descrição---------: Função utilizada para mostrar as configurações de tela do usuário	
Parametros--------: _nPosEnch,_nPosGetDados,_lDimensao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109S(_nPosEnch,_nPosGetDados,_lDimensao)

Local aObjects:= {}
Local aInfo   := {}
Local aPosObj := {}
aSize   := {}

Default _nPosEnch    := 0
Default _nPosGetDados:= 0
Default _lDimensao   :=.F.

// Obtém a a área de trabalho e tamanho da dialog
aSize := MsAdvSize()

aAdd( aObjects, { _nPosEnch    , _nPosEnch    , .T., .T.             } ) // Dados da Enchoice
aAdd( aObjects, { _nPosGetDados, _nPosGetDados, .T., .T. ,_lDimensao } ) // Dados da getdados

// Dados da área de trabalho e separação
aInfo 	:= { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3, 3, 3 } // Chama MsObjSize e recebe array e tamanhos

aPosObj := MsObjSize( aInfo, aObjects,.T.)

Return aPosObj

/*
===============================================================================================================================
Programa----------: AOMS109Legenda()
Autor-------------: Alex Wallauer
Data da Criacao---: 08/08/2018
Descrição---------: LEGENDA
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109Legenda()

Local aLegenda := {}

aAdd(aLegenda, {"BR_AZUL"   ,"PV com bloqueio de estoque"})
aAdd(aLegenda, {"BR_AMARELO","PV liberado para faturamento"})
aAdd(aLegenda, {"BR_VERDE"	,"PV sem liberação"})
aAdd(aLegenda, {"BR_VIOLETA","PV com bloqueio de crédito"})
aAdd(aLegenda, {"BR_BRANCO" ,"PV com bloqueio de preço"})
aAdd(aLegenda, {"BR_PRETO"  ,"PV com bloqueio de bonificação"})
aAdd(aLegenda, {"BR_MARRON"  ,"PV com bloqueio de logística"})

BrwLegenda("Legenda","Legenda",aLegenda)

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS109C()
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/10/2018
Descrição---------: Chamada de itens do menu
Parametros--------: _nopc - Opção do menu
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109C(_nopc)

Local oproc
Local _aMvPar := {}, _nI
Local _cParam 
Local _nRegAtu := TRBF->(Recno())
Local _cTextoMsg := ""

Private _cOper25 := Space(2)
Private _cLocal  := Space(2)

Begin Sequence 

Do Case

Case _nopc == 1 
	//Pesquisa
	FWMsgRun(,{ || AOMS109PSQ(oMark,"TRBF") }, "Aguarde...","Carregando dados...")

Case _nopc == 2
	//Visualiza pedido de vendas
	FWMsgRun(,{ || AOMS109PPV() }, "Aguarde...","Carregando dados...")
	
Case _nopc == 3
	//Analisa itens do pedido de vendas
	FWMsgRun(,{ || AOMS109AI(TRBF->TRBF_NUM) }, "Aguarde...","Carregando dados...")
	
Case _nopc == 4
	//Legenda do browse
	FWMsgRun(,{ || AOMS109Legenda() }, "Aguarde...","Carregando dados...")

Case _nopc == 7
    _lMsgEmTela := .T.
	//Estorna liberação de pedidos de vendas
	If U_ITMsg("Estorna liberação dos pedidos de vendas selecionados?","Atenção",,3,2,2)
      _lMsgEmTela := .F.
		FWMsgRun( , {|oproc| AOMS109EXE(oproc) }, "Aguarde!" , 'Carregando dados...' )
	EndIf
	
Case _nopc == 10 
   _lMsgEmTela := .T.
	//Atualiza browse
	If U_ITMsg("Atualiza tela?","Atenção","Todos os pedidos serão desmarcados!",3,2,2)
      _lMsgEmTela := .F.
		FWMsgRun( , {|oproc| AOMS109ARQ(oproc, .F.) }, "Aguarde!" , 'Carregando dados...' )
	EndIf
	
Case _nopc == 5 
	//Filtrar
	FWMsgRun( , {|oproc| AOMS109F(oproc) }, "Aguarde!" , 'Carregando dados...' )

Case _nopc == 6
	//Libera pedidos
   _lMsgEmTela := .T.
	If U_ITMsg("Libera pedidos de vendas selecionados?","Atenção",,3,2,2)
      _lMsgEmTela := .F.
		FWMsgRun( , {|oproc| AOMS109EX2(oproc) }, "Aguarde!" , 'Carregando dados...' )
	EndIf
   
	
Case _nopc == 11
   _lMsgEmTela := .T.
	//Envia WF de liberação
	If U_ITMsg("Envia WF de liberação dos pedidos de vendas selecionados?","Atenção",,3,2,2)
      _lMsgEmTela := .F.
		FWMsgRun( , {|oproc| AOMS109WF(oproc) }, "Aguarde!" , 'Carregando dados...' )
	EndIf
	
Case _nopc == 13
	//Manutenção de pedido de vendas
	FWMsgRun( , {|oproc| AOMS109MN(oproc) }, "Aguarde!" , 'Carregando dados...' )

Case _nopc == 9
	//Relatório de pré nota
	FWMsgRun( , {|oproc| AOMS109RL(oproc) }, "Aguarde!" , 'Carregando dados...' )

Case _nopc == 12
	//Alteração de produtos
	FWMsgRun( , {|oproc| AOMS109AT(oproc) }, "Aguarde!" , 'Carregando dados...' )

Case _nopc == 8
	//Corte de produtos
	FWMsgRun( , {|oproc| AOMS109CI(oproc) }, "Aguarde!" , 'Carregando dados...' )
	
Case _nopc == 14
	//Devolve RDC / TMS Multi-Embarcador.

   _cTextoMsg := "Devolve para o TMS?" 
   _lMsgEmTela := .T.
	If U_ITMsg(_cTextoMsg,"Atenção",,3,2,2)
      _lMsgEmTela := .F.
		FWMsgRun( , {|oproc| AOMS109DR(oproc) }, "Aguarde!" , 'Carregando dados...' )
	EndIf

Case _nopc == 15
   _lMsgEmTela := .T.
	//Devolve RDC ou TMS Multi-Embarcador.
	If U_ITMsg("Exporta tela para excel?","Atenção",,3,2,2)
      _lMsgEmTela := .F.
		FWMsgRun( , {|oproc| AOMS109EC(oproc) }, "Aguarde!" , 'Carregando dados...' )
	EndIf

Case _nopc == 16
	//Desmembramento
	FWMsgRun( , {|oproc| AOMS109DS() }, "Aguarde!" , 'Carregando dados...' )

Case _nopc == 17
	//Alteração
	FWMsgRun( , {|oproc| AOMS109AP() }, "Aguarde!" , 'Carregando dados...' )	

Case _nopc == 18
   _lMsgEmTela := .T.
	//Bloqueio logístico
	If U_ITMsg("Definir em Planejamento Logístico os pedidos selecionados?","Atenção",,3,2,2)	
      _lMsgEmTela := .F.
		FWMsgRun( , {|oproc| AOMS109BO(oproc) }, "Aguarde!" , 'Carregando dados...' )
	EndIf

Case _nopc == 19
    _lMsgEmTela := .T.
	//Desbloqueio logístico
	If U_ITMsg("Retirar de Planejamento Logístico os pedidos selecionados?","Atenção",,3,2,2)
      _lMsgEmTela := .F.
		FWMsgRun( , {|oproc| AOMS109DO(oproc) }, "Aguarde!" , 'Carregando dados...' )
	EndIf

Case _nopc == 20
	//Histórico
	FWMsgRun( , {|oproc| AOMS109HI() }, "Aguarde!" , 'Carregando dados...' )	

Case _nopc == 21
	//Transferência de pedidos

	Private _cFilTran := cfilant
    
	//=====================================================================================
	// Tratamentos que verificam se a rotina de transferência de pedidos já foi processada.
	//=====================================================================================
    TRBF->(DBGoTop())
	While ! TRBF->(Eof())
	   If IsMark( "TRBF_OK" , cMarkado ) 
	      aAdd(_aPVTransf,TRBF->(Recno()))
	   EndIf 
	   
	   TRBF->(DBSkip())
	EndDo 

	TRBF->(DBGoTo(_nRegAtu))

    //===================================================================================
	// Salva os MV_PAR do fonte AOMS109. Pois o fonte AOMS032 utiliza os próprios MV_PAR.
	//===================================================================================
	_aMvPar := {}
	
	For _nI := 1 To 60
        _cParam := "MV_PAR" + StrZero(_nI,2)
        
		If Type(_cParam) <> "U"
		   aAdd(_aMvPar,{_cParam, &(_cParam)})
		Else
		   aAdd(_aMvPar,{_cParam, Nil})
		EndIf 
	Next 

	While .T.

		DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("Transf Pedidos") From 0,0 To 200,300 OF oMainWnd PIXEL

    	oPanel       := TPanel():New(30,0,'',oDlg1,, .T., .T.,, ,315,60,.T.,.T. ) 
      
		@0.8,00.8 Say OemToAnsi("Filial de Destino:")				OF oPanel
		@0.8,0010 MsGet oFilTran	VAR _cFilTran	SIZE 50,8 F3 "LSTFIL" 	OF oPanel Picture "@!"

        @2 ,00.8 Say OemToAnsi("Operação:") OF oPanel  
        @2 ,0010 MsGet _oOper Var _cOper25 Picture "@!" F3 "ZB4" Valid(U_AOMS032Y('OPERACAO',_cOper25)) Size 30, 10 OF oPanel // Valid(ExistCpo("ZB4",_cOper25))

	    @3.2 ,00.8 Say OemToAnsi("Local/Armazém:") OF oPanel 
	    @3.2 ,0010 MsGet _oLocal Var _cLocal  Picture "@!" F3 "NNR"	Valid(U_AOMS032Y('LOCAL',_cLocal)) Size 30, 10 OF oPanel // Valid(ExistCpo("NNR",_cLocal))
	
   		ACTIVATE MSDIALOG oDlg1 ON INIT ( EnchoiceBar(oDlg1,{|| nOpca := 1,oDlg1:End() },{|| nOpca := 2,oDlg1:End()}))

		If nopca == 1
           //=======================================================================
		   // Ativa os MV_PAR do fonte AOMS032.
		   //=======================================================================
		   Pergunte("AOMS032",.F.)

			//Prepara tabela TRBT para o AOMS032
			AOMS109A2()

            MV_PAR18 := _cOper25
			MV_PAR19 := _cLocal
			
			If !(U_AOMS032VLD(nQtdTit,_cFilTran))
				Loop
			EndIf

			nRadMenu1 := 2
			FWMsgRun( , {|oproc| U_AOMS032EXE(oproc) }, "Aguarde!" , 'Processando transferência entre filiais...' )
            
		   //=======================================================================
		   // Restaura os MV_PAR do fonte AOMS109.
		   //=======================================================================
			Pergunte("AOMS109", .F. )

			For _nI := 1 To 60
                If &(_aMvPar[_nI,1]) <> Nil 
                   &(_aMvPar[_nI,1]) := _aMvPar[_nI,2]
				EndIf 
			Next 
            
		   //=======================================================================
		   // Remove do Browser os pedidos de vendas transferidos.
		   //=======================================================================
			For _nI := 1 To Len(_aPVTransf)
			    TRBF->(DBGoTo(_aPVTransf[_nI]))

			    //TRBF->(RecLock("TRBF",.F.))
	            TRBF->(DBDelete())
				//TRBF->(MSUnLock())
	        Next 

	        TRBF->(DBGoTop())
			oMark:oBrowse:Refresh()

		Else

			U_ITMsg("Transferência cancelada","Atenção",,1)

		EndIf

		Exit

	EndDo

Case _nopc == 22
    //U_ITMsg("Alteração de Armazens","Atenção",,1)
    //U_AOMS109G(oproc)
    FWMsgRun( , {|oproc| U_AOMS109G(oproc) }, "Aguarde!" , 'Processando alterações de armazens...' )

Case _nopc == 23 
    If U_ITMsg("Confirma o processamento da rotina de solicitação de retorno dos pedidos de vendas, do TMS para o Protheus?","Atenção",,3,2,2) 
       FWMsgRun( , {|oproc| U_AOMS109Y(oproc) }, "Aguarde!" , 'Processando Webservice Retorno PV do TMS para o Protheus...' )
	EndIf

OtherWise
   _lMsgEmTela := .T.
	U_ITMsg("Função em Desenvolvimento","Atenção",,1)
	_lMsgEmTela := .F.
EndCase

End Sequence 

Return

/*
===============================================================================================================================
Programa----------: AOMS109EC()
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/03/2019
Descrição---------: Exporta browse para o excel
Parametros--------: oproc - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109EC(oproc)

Local _acolec := {}
Local _aheaderec := {}

	//Monta aheader
	aAdd(_aheaderec,"Fil Car")
	aAdd(_aheaderec,"Fil Fat")
	aAdd(_aheaderec,"Tipo Ped")
	aAdd(_aheaderec,"Pedido")
	aAdd(_aheaderec,"Tipo de Entrega")  
	aAdd(_aheaderec,"Sit. Entrega")  
	aAdd(_aheaderec,"Peso")
	aAdd(_aheaderec,"Data Necess")
	aAdd(_aheaderec,"Data Entrega")
	aAdd(_aheaderec,"UF")
	aAdd(_aheaderec,"Cidade")
	aAdd(_aheaderec,"CEP")
	aAdd(_aheaderec,"Cliente")
	aAdd(_aheaderec,"Loja")
	aAdd(_aheaderec,"Descricao Cliente")
	aAdd(_aheaderec,"Rede")
	aAdd(_aheaderec,"Descricao Rede") 
	aAdd(_aheaderec,"Vendedor")
	aAdd(_aheaderec,"Descricao Vendedor")
	aAdd(_aheaderec,"Operação")
	aAdd(_aheaderec,"Data Emissao")
	aAdd(_aheaderec,"Data Liberação")
	aAdd(_aheaderec,"PV Vinculado")
    aAdd(_aheaderec,"Envio TMS ?")
	aAdd(_aheaderec,"Troca Nota?")
	aAdd(_aheaderec,"PV Remessa")
	aAdd(_aheaderec,"Classificacao Entrega")

	//Monta acols
	_nposi := TRBF->(Recno())
	TRBF->(DBGoTop())

	While !(TRBF->(Eof()))

		If IsMark( "TRBF_OK" , cMarkado )

  	       _cClassEnt:=Posicione("SA1",1,xFilial("SA1")+TRBF->TRBF_CODCL+TRBF->TRBF_LOJCL,"A1_I_CLABC")
		   If _cClassEnt = '1'
		      _cClassEnt:="1-TOP 1 NACIONAL"
		   ElseIf _cClassEnt = '2'
		      _cClassEnt:="2-TOP 5 Reg. SP "
		   ElseIf _cClassEnt = '3'
		      _cClassEnt:="3-TOP 5 Reg. RS "
		   EndIf

		   aAdd(_acolec, {	TRBF->TRBF_FILCR,;
    				TRBF->TRBF_FILFT,;
    				TRBF->TRBF_OPER,;
    				TRBF->TRBF_NUM,;
    				TRBF->TRBF_AGEND,;
    				TRBF->TRBF_STENT,;
    				TRBF->C5_I_PESBR,;
    				DToC(TRBF->TRBF_DTNES),;
    				DToC(TRBF->TRBF_DTENT),;
    				TRBF->TRBF_UF,;
    				TRBF->TRBF_MUN,;
    				TRBF->TRBF_CEP,;
    				TRBF->TRBF_CODCL,;
    				TRBF->TRBF_LOJCL,;
    				TRBF->TRBF_DESCL,;
    				TRBF->TRBF_CODRE,;
    				TRBF->TRBF_DESCR,;
    				TRBF->TRBF_CODVE,;
    				TRBF->TRBF_DESVE,;
    				TRBF->TRBF_OPER,;
    				DToC(TRBF->TRBF_DTEMI),;
    				DToC(TRBF->TRBF_DTLIB),;
    				TRBF->C5_I_PEVIN,;
    				If(TRBF->C5_I_ENVRD="S","Sim","Não"),;
    				If(TRBF->C5_I_TRCNF="S","Sim","Não"),;
    				TRBF->C5_I_PVREM,_cClassEnt} )

		EndIf

		TRBF->(DBSkip())

	EndDo

	//Apresenta itlist
	If Len(_acolec) > 0

		U_ITListBox( "Pedidos de venda" , _aheaderec , _acolec , .T. , 1 )

	Else

		U_ITMsg("Nenhum registro selecionado!","Atenção",,1)

	EndIf

	TRBF->(DBGoTo(_nposi))

Return

/*
===============================================================================================================================
Programa----------: AOMS109F()
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/10/2018
Descrição---------: Carrega novo filtro
Parametros--------: oproc - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109F(oproc)

If !Pergunte( cPerg , .T. )
	Return
EndIf
       
//================================================================================
// Cria o arquivo Temporario para insercao dos dados selecionados.
//================================================================================
FWMsgRun( , {|oproc| _nControle := AOMS109ARQ(oproc, .T.) }, "Aguarde!" , 'Lendo Dados dos pedidos...' )

Return

/*
===============================================================================================================================
Programa----------: AOMS109EX2
Autor-------------: Josué Danich Prestes
Data da Criacao---: 20/07/2018
Descrição---------: Função que libera pedidos de venda
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109EX2(oproc)
Local _aLstPedV := {}
Local _nI 

//=====================================================================
// Retorna um Array com grupos de produtos selecionados pelo usuário.
//=====================================================================
_aLstPedV := RetSelecPV() 

//=================================================
// Se não tem pedido selecionado já sai da rotina
//=================================================
If Empty(_aLstPedV) // Empty(_cNumPed)
   U_ITMsg("Nenhum pedido selecionado","Atenção",,1)
   TRBF->(DBGoTop())
   Return
EndIf

//============================================================
// Faz a liberação por grupos de pedidos de vendas.
//============================================================	

//================================================================================
// Percorre os pedidos selecionados e monta o cabecalho e itens do pedido de venda
//================================================================================
Begin Transaction
   _npv := 0
   _alista := {}
   SC5->(DBSetOrder(1))
   SA1->(DBSetOrder(1))
   SC9->(DBSetOrder(1))
   
   For _nI := 1 To Len(_aLstPedV)	

	   SC5->(DBGoTo(_aLstPedV[_nI,3]))	
	   _cNumPed := SC5->C5_NUM         
	   _npv++
		
	   // Atualiza régua
	   oproc:cCaption := ("Processando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	   ProcessMessages()
		
	   //=======================================================================================================
	   // Caso outro usuario exclua, fature ou carregue o Pedido de Venda posteriormente ao usuario ter 
	   // filtrado os dados
	   //========================================================================================================
	   If Empty(SC5->C5_NOTA) .And. (!SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .Or. (Empty(SC9->C9_CARGA) .And. Empty(SC9->C9_NFISCAL) ) ) // ( SC5->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. 
					
          _nSalvaRecRDC := 0
  		  If SC5->C5_I_ENVRD = "S"
		     SC5->(RecLock("SC5",.F.))
		     SC5->C5_I_ENVRD := "N"
		     SC5->(MSUnLock())
             _nSalvaRecRDC:=SC5->(RECNO())
          EndIf

		  oproc:cCaption := ("Liberando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
		  ProcessMessages()
            
          _cmsglibpv := AOMS109LP(oproc)//faz liberação de estoque para o item de pedido de vendas

		  U_MOMS042P("S")

  		  If _nSalvaRecRDC <> 0
  		     SC5->(DBGoTo(_nSalvaRecRDC))
		     SC5->(RecLock("SC5",.F.))
		     SC5->C5_I_ENVRD := "S"               
			 SC5->( MSUnLock() )
          EndIf
						
          If ! Empty(_cmsglibpv) 
		     _cErro:="Erro ao liberar o PV: "
	         _cErro+=_cmsglibpv
			 aAdd(_alista,{_cNumPed,_cErro})
		  Else
		     aAdd(_alista,{_cNumPed, "LIBERADO COM SUCESSO"})
		     If _nSalvaRecRDC <> 0
			    oproc:cCaption := ("Enviando Status TMS do PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
				    
			    ProcessMessages()
			    U_ENVSITPV()//lret := startjob("U_ ENVSITPV",getenvserver(),.F.,,.F.)   //Envia interface de alteração de situação do pedido atual
			 EndIf
		  EndIf
	   Else
		  //Registra problema com pedido
		  If !SC5->( DBSeek( xFilial("SC5") + _cNumPed ) )
		     aAdd(_alista,{_cNumPed, "Pedido foi EXCLUIDO antes do processamento"})
		  ElseIf !Empty(SC5->C5_NOTA) 
		     aAdd(_alista,{_cNumPed, "Pedido foi FATURADO antes do processamento"})
  		  ElseIf SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. (!Empty(SC9->C9_CARGA) .Or. !Empty(SC9->C9_NFISCAL) )
  		     aAdd(_alista,{_cNumPed, "Pedido CARREGADO antes do processamento"})
		  ElseIf !SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM))
		     aAdd(_alista,{_cNumPed, "Falha na liberação do pedido"})
	      EndIf
	   EndIf
   Next	

End Transaction

If Len(_alista) > 0
	U_ITListBox( "Pedidos liberados" , {"Numero","Situacao"} , _alista , .T. , 1 )
EndIf

//Atualiza tela
FWMsgRun( , {|oproc| AOMS109ARQ(oproc) }, "Aguarde!" , 'Carregando dados...' )

Return

/*
===============================================================================================================================
Programa----------: AOMS109LP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 20/07/2018
Descrição---------: Função que Processa a liberação pedidos de venda
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109LP(oproc)

Local _cmsg := ""
Local _apedidos := {}
Local _cPedidos := ""
Local _cTextoCred := ""
Local _lblest := .F.
Local _nQtdLib:=0

Begin Transaction

Begin Sequence

      
SC6->(DBSetOrder(1))
SC9->(DBSetOrder(1))
SA1->(DBSetOrder(1))
SB2->(DBSetOrder(1))

// Monta valor total do pedido
ntotped := 0
   
SC6->(DBSetOrder(1))
If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

	While SC6->C6_FILIAL + SC6->C6_NUM == SC5->C5_FILIAL+SC5->C5_NUM
		ntotped += SC6->C6_VALOR
        SC6->( DBSkip())
    EndDo
    
Else

	_cmsg := "Não foram localizados itens para o pedido"
	Break

EndIf

If SC5->C5_I_BLCRE == "R"

	_cmsg += "PV com Rejeição de Crédito"
	Break

EndIf
              
SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

_aAprovacao := AOMS109AC()     // Verifica as aprovações de credito.
_lAprov     := _aAprovacao[1] // True = Credito aprovado / False = Credito reejeitadao
_cTextoRet  := _aAprovacao[2] // Mensagem de retorno.   

If ! _lAprov    

    _cmsg += _cTextoRet + " ### " // " Erro na liberação de crédito do Pedido de Vendas: "+AllTrim(SC5->C5_NUM) 
             	               
    SC5->(RecLock("SC5",.F.))
    SC5->C5_I_BLCRE	:= "B"
    SC5->C5_I_DTAVA := Date()
	SC5->C5_I_HRAVA := Time()
	SC5->C5_I_USRAV := cUserName
	SC5->C5_I_MOTBL := _cTextoRet
	SC5->(MSUnLock())
	Break

Else

	If SC5->C5_I_BLPRC == "B" .Or. SC5->C5_I_BLPRC == "R"
	
		 _cmsg += "PV com bloqueio de Preço"
		 Break
		 
	EndIf
	
	If SC5->C5_I_BLOQ == "B" .Or. SC5->C5_I_BLOQ == "R"
	
		 _cmsg += "PV com bloqueio de bonificação"
		 Break
		 
	EndIf

EndIf

             
_cChavePesq := ""
_aJaProces  := {}  
                
//========================================================================================
// Se a função AOMS109AC() retornar verdadeiro, este trecho realiza várias validação.
// valida crédito, estoque, etc. Utilizando outros métodos.
//========================================================================================
If RecLock("SC5",.F.) .And. _lAprov
   SC6->(DBSetOrder(1))
   SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
   While !(SC6->(Eof())) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->C5_FILIAL+SC5->C5_NUM
      _cChavePesq := SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM  // Para evitar que o mesmo item de pedido seja processado mais de uma vez 
      If aScan(_aJaProces,_cChavePesq) == 0
         aAdd(_aJaProces,_cChavePesq)
      Else
         SC6->(DBSkip())
         Loop
      EndIf
      
      SC9->(DBSetOrder(1))
  	  If !(SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))) .Or. !Empty(SC9->C9_BLEST)  // verifica estoque se não tem liberação válida ainda	
  	  	 //Verifica se pode gravar registros do C6, A1 e B2
  	  	 _lflock := .F.
  	  	
   	  	 If !SC6->(MsRLock(SC6->(RECNO())))
  	  		_cmsg += "No momento este Pedido de Vendas está sendo utilizado por outro usuário e não pode ser manipulado. Tente integrar novamente mais tarde: " + SC6->C6_NUM + "/" + SC6->C6_ITEM
   	  		_lflock := .T.
  	  	 EndIf
  	  	
  	  	 SA1->(DBSetOrder(1))
  	  	 SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
  	  	 
  	  	 SB2->(DBSetOrder(1)) 	  	
  	  	 SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL))
  	  	
  	  	 If ! _lflock .And. !SB2->(MsRLock(SB2->(RECNO())))
  	  		_cmsg += "No momento este estoque está sendo utilizado por outro usuário e não pode ser manipulado. Tente integrar novamente mais tarde: " + SB2->B2_COD + "/" + SB2->B2_LOCAL
  	  		_lflock := .T.
  	  	 EndIf
  	           	         
         If _lflock .And. !Empty(_cMsg)  //Break exclusivo para falha de lock dos itens
         	DisarmTransaction()
        	Break
         EndIf
   
         SC9->(DBSetOrder(1))
      	 If (SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))) .And. !Empty(SC9->C9_BLEST)
      	 	SC9->(A460Estorna()) //Se já tem sc9 com bloqueio de estoque estorna a liberação
      	 EndIf
      	 
  	     _nQtdLib := MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN)//LIBERA PEDIDO   
  	     
  	     //Analise da liberação de estoque
  	     _lestoque := .F.
  	     _lblest := .F.
  	     
  	     SC9->(DBSetOrder(1))
  	     If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM)) 
  	     	If SC9->C9_QTDLIB <> SC6->C6_QTDVEN  		        	 
  	     	   _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". A quantidade liberada diverge da quantidade do item: " + SC6->C6_ITEM + " - Produto: " +;
  	           SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
  	        ElseIf !Empty(SC9->C9_BLEST)   
  	           _nQtdEst := 0
  	           If SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL))
  	              _nQtdEst := (SB2->B2_QATU - SB2->B2_QEMP - SB2->B2_QEMPN - SB2->B2_RESERVA - SB2->B2_QACLASS)
  	           EndIf
  	         	           
               _lBloqEst   := .T.
               _lblest := .T.
  	   
  	        ElseIf !Empty(SC9->C9_BLCRED) 
               _cPedidos += " Nr.Pedido V.: " + AllTrim(SC6->C6_NUM) + " - Item: " + SC6->C6_ITEM + " - Produto: "+AllTrim(SC6->C6_PRODUTO) + " - Qtd: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+". ### " 
            ElseIf !Empty(SC9->C9_CARGA) 
  	           _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Bloqueio de carga para o item: " + SC6->C6_ITEM + " - Produto: " +;
  	           SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
            ElseIf !Empty(SC9->C9_NFISCAL) 
  	           _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Bloqueio de nota fiscal para o item: " + SC6->C6_ITEM + " - Produto: " +;
  	           SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"."               		        	     
            Else
  	           _lestoque := .T.
	        EndIf
  	     Else
   	     	_cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Não foi gerado registro de liberação " + SC6->C6_ITEM + " - Produto: " +;
   	     		SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
  	     EndIf
 
   	     If _lestoque .Or. _lblest
  	        aAdd(_apedidos,SC6->C6_NUM)
  	        MSUnLockAll()
  		    RecLock("SC5",.F.)
 		    SC5->C5_LIBEROK := "S"
 		    MSUnLockAll()
 		 EndIf
 
 	  ElseIf SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM)) 
 
 		 If SC9->C9_QTDLIB <> SC6->C6_QTDVEN
 		 	_cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". A quantidade liberada diverge da quantidade do item: " + SC6->C6_ITEM + " - Produto: " +;
 		 	SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
 		 ElseIf !Empty(SC9->C9_BLEST) 

 		 	_cTextoMsg := " Erro na liberação do Estoque do PV: "+AllTrim(SC6->C6_NUM)+". Item: " + SC6->C6_ITEM + " - " +;
 		 					AllTrim(SC6->C6_PRODUTO) + ". Qtd PV: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+" "+SC6->C6_UM+". Armazém: " + SC6->C6_LOCAL +;
 		 					". Qtd Estoque: " + AllTrim(Str(_nQtdEst,18,5)) + " " + SC6->C6_UM    
            _lBloqEst   := .T.
  	        If !(_cTextoMsg $ _cMsg)
  	           _cMsg += _cTextoMsg
  	        EndIf   
  	        
 		 ElseIf !Empty(SC9->C9_BLCRED)              
 		    _cPedidos += " Nr.Pedido V.: " + AllTrim(SC6->C6_NUM) + " - Item: " + SC6->C6_ITEM + " - Produto: "+AllTrim(SC6->C6_PRODUTO) + " - Qtd: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+". ### " 
 		 ElseIf !Empty(SC9->C9_CARGA) 
 		    _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Bloqueio de carga para o item: " + SC6->C6_ITEM + " - Produto: " +;
 		    	SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
 		 ElseIf !Empty(SC9->C9_NFISCAL) 
 		    _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Bloqueio de nota fiscal para o item: " + SC6->C6_ITEM + " - Produto: " +;
 		    	SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"."               		        	     
 		 Else
 	        aAdd(_apedidos,SC6->C6_NUM)
  	        MSUnLockAll()
  		    RecLock("SC5",.F.)
 		    SC5->C5_LIBEROK := "S"
 		    MSUnLockAll()
 		 EndIf 
  	  Else
  	     _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Não foi gerado registro de liberação " + SC6->C6_ITEM + " - Produto: " +;
  	              SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
  	  EndIf  

      SC6->(DBSkip())
   EndDo
       
   If ! Empty(_cPedidos) .And. ! _cPedidos $ _cMsg
      _cMsg += " Erro na liberação do Pedido de Vendas. Bloqueio por Crédito: " + _cPedidos
   EndIf
   
   If !Empty(_cMsg)   
      DisarmTransaction()	
      MSUnLockAll() 
      Break
   EndIf

Else

   //========================================================================================
   // Se a função AOMS109AC() retornar falso na validação do crédito, volta toda a transação 
   // das tabelas e retorna a(s) mensagem(ns) de rejeição.
   //========================================================================================       
   
   _cMsg += _cTextoCred  
   MSUnLockAll()
   DisarmTransaction()		         
	              
   Break

EndIf
   
If ! Empty(_cMsg)

	MSUnLockAll()
    DisarmTransaction()
    Break

ElseIf _lblest

	_cMsg := "Bloqueio de estoque na liberação do PV"

EndIf

End Sequence
      
MSUnLockAll()

End Transaction

Return _cMsg

/*
===============================================================================================================================
Programa--------: AOMS109AC
Autor-----------: Josué Danich Prestes
Data da Criacao-: 18/02/2014
Descrição-------: Valida Limite de Crédito do Cliente para gravação da carga
Parametros------: cNumPed - Número do pedido de venda do portal
----------------: cFilAux - Filial do pedido de venda
Retorno---------: array com  duas posições - lRet    - Informa o resultado da validação, ctext - texto de avaliação
===============================================================================================================================
*/
Static Function AOMS109AC( cNumPed , cFilAux, Altera )

Local aAreaSC5	:= GetArea("SC5")
Local aAreaSC6	:= GetArea("SC6")
Local aAreaSA1	:= GetArea("SA1")
Local _ntotped 	:= 0

Local _lRet := .T.   // "Outros"
Local _nTotPV:=0
Local _lValCredito:=.T.
Local _cTextoRet := "Aprovado em avalição de crédito"
Local _cchep := AllTrim(GetMV("IT_CCHEP"))


Default cNumPed	:= SC5->C5_NUM //Número do Pedido Posicionado
Default cFilAux	:= SC5->C5_FILIAL //Filial do Pedido Posicionado

Default altera := .T.

Begin Sequence

SC6->(DBSetOrder(1))
SC5->(DBSetOrder(1))

SC6->(DBGoTop())
SC5->(DBGoTop())

If !(SC6->(DBSeek(cFilAux+cNumPed))) .Or. !(SC5->(DBSeek(cFilAux+cNumPed)))

	  _lRet      := .F. 
      _cTextoRet := "Filial : " + cFilAux + " / Pedido: " + cNumPed + ". Não Localizado. "
      Break

Else

   While SC6->C6_FILIAL == cFilAux .And. SC6->C6_NUM == cNumPed
	   
	      
      _nTotPV += SC6->C6_VALOR

      If AllTrim(SC6->C6_PRODUTO) == _cchep .Or. AllTrim(SC6->C6_CF) $ '5910/6910/5911/6911'//NÃO VALIDA CRÉDITO PARA PALLET CHEP E PARA BONIFICAÇÃO
          _lValCredito:=.F.
          Exit
      EndIf

      If Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") != 'S' //NÃO VALIDA CRÉDITO PARA PEDIDO SEM DUPLICATA
          _lValCredito:=.F.
          Exit
      EndIf
    
      If Posicione("ZAY",1,xFilial("ZAY")+ AllTrim(SC6->C6_CF) ,"ZAY_TPOPER") != 'V' //NÃO VALIDA CRÉDITO PARA PEDIDO COM CFOP QUE NÃO SEJA DE VENDA
          _lValCredito:=.F.
          Exit
      EndIf
 
       _ntotped += (SC6->C6_QTDVEN * SC6->C6_PRCVEN) 
    	
       SC6->(DBSkip())
      
   EndDo

EndIf

If _lValCredito

	_aRetCre := U_ValidaCredito( _nTotPV , SC5->C5_CLIENTE , SC5->C5_LOJACLI , Altera , , , , SC5->C5_MOEDA,,SC5->C5_NUM)//AWF-11/01/2017
	_cBlqCred:=_aRetCre[1]
	
	 If _aRetCre[2] = "B"//Se bloqueou

			_lRet      := .F. 
            _cTextoRet := "Pedido de vendas " + AllTrim(SC5->C5_NUM) + " bloqueado por crédito, " + _cBlqCred
            Break
	 EndIf
	 
Else

	_lRet := .T.
	_cTextoRet := "Pedido não passa por avaliação de crédito"

EndIf


End Sequence

SC5->(FWRestArea(aAreaSC5))
SC6->(FWRestArea(aAreaSC6))
SA1->(FWRestArea(aAreaSA1))

Return( {_lRet,_cTextoRet} )

/*
===============================================================================================================================
Programa--------: AOMS109CL
Autor-----------: Josué Danich Prestes
Data da Criacao-: 18/02/2014
Descrição-------: Retorna cor e legenda
Parametros------: Nenhum
Retorno---------: string com cor da legenda da linha posicionada no TRBF
===============================================================================================================================
*/
User Function AOMS109CL()

Local _ccor := "BR_VERDE"

If TRBF->C5_LIBEROK == 'S'

	If TRBF->QTDBLOQEST == 0

		_ccor := "BR_AMARELO" //Liberacao de estoque ok
		
	Else
	
		_ccor := "BR_AZUL" //Liberacao de estoque com bloqueio de produto
		
	EndIf
	
EndIf

If TRBF->C5_I_BLCRE=="B" .Or. TRBF->C5_I_BLCRE=="R"

	_ccor := "BR_VIOLETA" //Bloqueio de crédito
	
EndIf  

If TRBF->C5_I_BLPRC == 'B' .Or. TRBF->C5_I_BLPRC == 'R'

	_ccor := "BR_BRANCO" //Bloqueio de preço
	
EndIf  

If TRBF->C5_I_BLOQ == 'B' .Or. TRBF->C5_I_BLOQ == 'R'

	_ccor := "BR_PRETO" //Bloqueio de bonificação
	
EndIf  

If TRBF->C5_LIBEROK != 'S' .And. TRBF->C5_I_BLOG == 'S'

_ccor := "BR_MARRON" //Bloqueio de logistica
	
EndIf 


Return _ccor

/*
===============================================================================================================================
Programa----------: AOMS109WF
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Função que envia wf de liberação de PV
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109WF(oproc)
Local _aLstPedV := {}
Local _nI 

//=====================================================================
// Retorna um Array com grupos de produtos selecionados pelo usuário.
//=====================================================================
_aLstPedV := RetSelecPV() 

//Se não tem pedido selecionado já sai da rotina
If Empty(_aLstPedV) //Empty(_cNumPed)
   U_ITMsg("Nenhum pedido selecionado","Atenção",,1)
   TRBF->(DBGoTop())
   Return
EndIf

//============================================================
// Envia Wf de liberação por grupos de pedidos de vendas.
//============================================================	

//================================================================================
// Percorre os pedidos selecionados e monta o cabecalho e itens do pedido de venda
//================================================================================
Begin Transaction
   _npv := 0
   _alista := {}
   SC5->(DBSetOrder(1))
   SA1->(DBSetOrder(1))
   SC9->(DBSetOrder(1))
	   
   For _nI := 1 To Len(_aLstPedV) 		

       SC5->(DBGoTo(_aLstPedV[_nI,3]))
	   
	   _cNumPed := SC5->C5_NUM         
	   _npv++
		
	    //Atualiza régua
        oproc:cCaption := ("Processando PV: " + SC5->C5_NUM + " [" + StrZero(_npv,6) + "] de [" + StrZero(nQtdTit,6) + "]")
		ProcessMessages()

        //=======================================================================================================
		// Caso outro usuario exclua, fature ou carregue o Pedido de Venda posteriormente ao usuario ter 
		// filtrado os dados
		//========================================================================================================
		If Empty(SC5->C5_NOTA) .And. (!SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .Or. (Empty(SC9->C9_CARGA) .And. Empty(SC9->C9_NFISCAL) ) ) // ( SC5->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. 
					
		   oproc:cCaption := ("Enviando WF liberação para PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
		   ProcessMessages()
            
           _cmsglibpv := AOMS109EX3(oproc)//faz liberação de estoque para o item de pedido de vendas
			
		   If !Empty(_cmsglibpv)
			  aAdd(_alista,{_cNumPed,_cmsglibpv})
		   EndIf
        Else
		   //Registra problema com pedido
		   If !SC5->( DBSeek( xFilial("SC5") + _cNumPed ) )
		      aAdd(_alista,{_cNumPed, "Pedido foi EXCLUIDO antes do processamento"})
		   ElseIf !Empty(SC5->C5_NOTA) 
			  aAdd(_alista,{_cNumPed, "Pedido foi FATURADO antes do processamento"})
  		   ElseIf SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. (!Empty(SC9->C9_CARGA) .Or. !Empty(SC9->C9_NFISCAL) )
  			  aAdd(_alista,{_cNumPed, "Pedido CARREGADO antes do processamento"})
           EndIf
 	   EndIf
   Next

End Transaction

If Len(_alista) > 0
	U_ITListBox( "Pedidos com WF liberação enviados" , {"Numero","Situacao"} , _alista , .T. , 1 )
EndIf
	
//Atualiza tela
FWMsgRun( , {|oproc| AOMS109ARQ(oproc) }, "Aguarde!" , 'Carregando dados...' )

Return

/*
===============================================================================================================================
Programa----------: AOMS109EX3
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Função que executa wf de liberação de PV
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: _cmsg - status do envio
===============================================================================================================================
*/
Static Function AOMS109EX3(oproc)

Local _cMsg 	:= "WF não enviado"
Local _cBlqCre	:= SC5->C5_I_BLCRE
Local _cBlqPre	:= SC5->C5_I_BLPRC
Local _cBlqBon	:= SC5->C5_I_BLOQ
Local _lRet		:= .F.

If _cBlqCre == "R" .Or. _cBlqCre == "B" .or.;
	_cBlqPre == "R" .Or. _cBlqPre == "B" .or.;
	_cBlqBon == "R" .Or. _cBlqBon == "B" 

	_lRet := U_MOMS030W() //Envia Wfs de liberação necessários 

	If _lRet
		_cMsg := "WF de liberação de pedido de vendas enviado com sucesso."
	Else
		_cMsg := "Falha no envio de solicitação de liberação!"
	EndIf
	
Else

	_cMsg := ""
	
EndIf

Return _cMsg

/*
===============================================================================================================================
Programa----------: AOMS109MN
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Função que chama manutenção de pedido de venda
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109MN(oproc)

Private aRotina := {}
Private cCadastro := ""
Private Inclui  := .F.
Private Altera  := .F.
Private l410auto:= .F.
aRotina := {{"Pesquisar", "AxPesqui", 0, 1},;
            {"Visualizar", "AxVisual", 0, 2},;
            {"Incluir", "AxInclui", 0, 3},;
            {"Alterar", "AxAltera", 0, 4},;                    
            {"Excluir", "AxDeleta", 0, 5}}
cCadastro:= "Manutenção do pedido de vendas " + TRBF->TRBF_NUM
Inclui  := .F.
Altera  := .F.
l410auto:= .F.
//=======================================================================================================
// Caso outro usuario exclua, fature ou carregue o Pedido de Venda posteriormente ao usuario ter 
// filtrado os dados
//========================================================================================================
If ( SC5->( DBSeek( TRBF->( TRBF_FILIA + TRBF_NUM ) ) ) .And. Empty(SC5->C5_NOTA) ) .AND.;
       (!SC9->(DBSeek(TRBF->( TRBF_FILIA + TRBF_NUM))) .Or. (Empty(SC9->C9_CARGA) .And. Empty(SC9->C9_NFISCAL) ) )
    
    _dtent := SC5->C5_I_DTENT
    _nposi := SC5->(Recno())
            
    U_AOMS026("SC5",_nposi,4)
    
    SC5->(DBGoTo(_nposi))
    
    //Se mudou a data de entrega atualiza data de necessidade antes de atualizar a tela
    If _dtent != SC5->C5_I_DTENT
    
      	aheader := {}
    	acols := {}
    	aAdd(aheader,{1,"C6_ITEM"})
    	aAdd(aheader,{2,"C6_PRODUTO"})
    	aAdd(aheader,{3,"C6_LOCAL"})

    	SC6->(DBSetOrder(1))
    	SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
		
    	While SC6->(!Eof()) .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->C5_NUM == SC6->C6_NUM
    		aAdd(acols,{SC6->C6_ITEM,SC6->C6_PRODUTO,SC6->C6_LOCAL})
    		SC6->(DBSkip())
    	EndDo
	
    	
	
    	_dneces := SC5->C5_I_DTENT - (U_OMSVLDENT(SC5->C5_I_DTENT,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FILFT,SC5->C5_NUM,1))
	
    	SC5->(DBGoTo(_nposi))
    	If _dneces != SC5->C5_I_DTNEC .And. SC5->(MsRLock(SC5->(RECNO())))
    		SC5->C5_I_DTNEC := _dneces
    		SC5->(MSUnLock())
     	EndIf
    
    
    EndIf
    
    //Atualiza tela
    FWMsgRun( , {|oproc| AOMS109ARQ(oproc) }, "Aguarde!" , 'Carregando dados...' )
    						
Else
			
	//Registra problema com pedido
	If !SC5->( DBSeek( TRBF->( TRBF_FILIA + TRBF_NUM ) ) )
			
		U_ITMsg("Pedido foi EXCLUIDO antes do processamento","Atenção",,1)
			
	ElseIf !Empty(SC5->C5_NOTA) 
			
		U_ITMsg("Pedido foi FATURADO antes do processamento","Atenção",,1)
			
	ElseIf SC9->(DBSeek( TRBF->( TRBF_FILIA + TRBF_NUM ))) .And. (!Empty(SC9->C9_CARGA) .Or. !Empty(SC9->C9_NFISCAL) )

		U_ITMsg("Pedido CARREGADO antes do processamento","Atenção",,1)
						
	EndIf
			 
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS109RL
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Chamada de relatório de pré nota para pedidos selecionados
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109RL(oproc)

Private cPerg		:= "ROMS007"   
Private cComboTpCa	:= {}
Private _aTpCarga 	:= {}

Begin Sequence 

   If _nQtdPvSel > 800
      U_ITMsg("Foram seleciondos mais de 800 Pedidos de Vendas para Impressão.","Atenção", "Selecione no máximo 800 registros para impressão.",1)
	  Break
   EndIf 
   
   //Utilizado para pegar dinamicamento o tipo da carga
   DBSelectArea("SX3")
   SX3->(DBSetOrder(2))
   If SX3->(DBSeek("DAK_I_TPCA"))
	  cComboTpCa := X3Cbox()
   EndIf     
		
   _aTpCarga := StrTokArr(cComboTpCa, ';')  

   oReport := U_ROMS007R()   
   oReport:PrintDialog()

   TRBF->(DBGoTop())
End Sequence 

Return

/*
===============================================================================================================================
Programa----------: AOMS109AT
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Alteração Massiva de produtos em PVs
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109AT(oproc)

Local _oDlg2 		:= nil
Local nLinha:=10
Local _nCol:=15
Local _aLstPedV  := {}
Local _nI 
Local _nJ 

Private _ccomps		:= ""
Private _ccompd		:= ""
Private _Acomps       := {}
Private _ocomps       := nil
Private _Acompd       := {}
Private _ocompd       := nil
Private _lsai         := .T.

//=====================================================================
// Retorna um Array com grupos de produtos selecionados pelo usuário.
//=====================================================================
_aLstPedV  := RetSelecPV() 

//======================================
// Se não tem registros já retorna
//======================================
If Empty(_aLstPedV )	// Empty(_cNumPed)
   U_ITMsg("Nenhum registro selecionado","Atenção",,1)
   TRBF->(DBGoTop())
   Return
EndIf

//============================================================
// Faz a alteração em massa de produtos do pedidos de vendas.
//============================================================	
SC6->(DBSetOrder(1))

//================================================================================
// Monta o cabecalho do pedido de venda
//================================================================================
For _nI := 1 To Len(_aLstPedV )
    
	SC6->(MsSeek(_aLstPedV[_nI,1] + _aLstPedV[_nI,2]))

    While ! SC6->(Eof()) .And. SC6->C6_FILIAL + SC6->C6_NUM == _aLstPedV[_nI,1] + _aLstPedV[_nI,2]
	   _nJ := aScan(_ACOMPS,{|x| SubStr(x,1,15) == SC6->C6_PRODUTO})
	   If _nJ == 0
          aAdd(_ACOMPS,SC6->C6_PRODUTO + " - " + SC6->C6_DESCRI )
	   EndIf 

       SC6->(DBSkip())
	EndDo 
Next 

DEFINE MSDIALOG _oDlg2 TITLE ("Alteração de produto em PVs") From 0,0 To 285, 650 OF oMainWnd PIXEL
    @ nLinha,_nCol Say OemToAnsi("Selecione o produto de origem:")
    nLinha+=12

    _ocomps := TComboBox():New(nLinha,_nCol,{|u|If(PCount()>0,_ccomps:=u,_ccomps)}, _acomps,250,20,_oDlg2,,;
							{|| AOMS109CH(_acomps[_ocomps:nat])},,,,.T.,,,,,,,,,'') //40
    nLinha+=38

    @ nLinha,_nCol Say OemToAnsi("Selecione o produto de destino:")
    nLinha+=12

    _ocompd := TComboBox():New(nLinha,_nCol,{|u|If(PCount()>0,_ccompd:=u,_ccompd)}, _acompd,250,20,_oDlg2,,,,,,.T.,,,,,,,,,'') //40
    nLinha+=38

    AOMS109CH(_acomps[1])

    @ nLinha,_nCol    Button "Altera" SIZE 41,15 ACTION ( FWMsgRun(, { |oproc| AOMS109EX5(oproc) }, "Aguarde...","Alterando pedidos...") ,TRBF->(DBGoTop()), IIf(_lsai,_oDlg2:End(),_lsai:= .T.)) Pixel 
    @ nLinha,_nCol+57 Button "Cancela"     SIZE 41,15 ACTION ( TRBF->(DBGoTop()),_oDlg2:End() ) Pixel 

ACTIVATE MSDIALOG _oDlg2 

Return

/*
===============================================================================================================================
Programa----------: AOMS109EX5
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Execução de alteração de produtos de PVs
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109EX5(oproc)

Local _aLstPedV := {}
Local _nI 

Private lMsErroAuto	:= .F.                        

//Se produto origem é igual ao produto destino ou produto destino está vazio finaliza o processo
If SubStr(_acomps[_ocomps:nat],1,11) == SubStr(_acompd[_ocompd:nat],1,11) .Or. Empty(SubStr(_acompd[_ocompd:nat],1,11))

	U_ITMsg("Produto destino inválido","Atenção",,1)
	_lsai := .F.
	Return
	
EndIf

//==================================================
// Retorna Array com filial, Nr. PV e recno do PV. 
//==================================================
_aLstPedV  := RetSelecPV() 

//==================================
// Se não tem registros já retorna
//==================================
If Empty(_aLstPedV)	// Empty(_cNumPed)
   U_ITMsg("Nenhum registro selecionado","Atenção",,1)
   TRBF->(DBGoTop())
   Return
EndIf
	
//================================================================================
// Percorre os pedidos selecionados e monta o cabecalho e itens do pedido de venda
//================================================================================
_npv := 0
_alista := {}
SC5->(DBSetOrder(1))
SA1->(DBSetOrder(1))
SC9->(DBSetOrder(1))

For _nI := 1 To Len(_aLstPedV )	
	
	SC5->(DBGoTo(_aLstPedV[_nI,3]))

	_cNumPed := SC5->C5_NUM         
	_npv++
		
	//Atualiza régua
	oproc:cCaption := ("Processando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	ProcessMessages()
		
	//=======================================================================================================
	// Caso outro usuario exclua, fature ou carregue o Pedido de Venda posteriormente ao usuario ter 
	// filtrado os dados
	//========================================================================================================
	If Empty(SC5->C5_NOTA) .And. ((( SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. Empty(SC9->C9_CARGA) .And. Empty(SC9->C9_NFISCAL) )).OR. !( SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)))) // ( SC5->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. 
	   // Grava se o pedido tem liberação de estoque		
	   If SC9->C9_FILIAL == SC5->C5_FILIAL .And. SC9->C9_PEDIDO == SC5->C5_NUM
		  _ltemlib := .T.
	   Else
		  _ltemlib := .F.
	   EndIf
			
	   oproc:cCaption := ("Alterando produto para PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	   ProcessMessages()
            
  	   lMsErroAuto := .F.
       AOMS109EA()//ALTERA PRODUTO DO PEDIDO DE VENDAS
						
	   If !lMsErroAuto 
						
		  //Se tinha liberação de estoque refaz a liberação
		  If _ltemlib
		     oproc:cCaption := ("Liberando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
		     ProcessMessages()
             _cmsglibpv := AOMS109LP(oproc)//faz liberação de estoque para o item de pedido de vendas
				   
		     If !Empty(_cmsglibpv) 
		
		   		_cErro:="Erro ao liberar o PV: "
		   		_cErro+=_cmsglibpv
		   		aAdd(_alista,{_cNumPed,_cErro})
		     EndIf
		  EndIf
				
		  If SC5->C5_I_ENVRD = 'S'
             oproc:cCaption := ("Enviando Status TMS do PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
  			 ProcessMessages()
		     U_ENVSITPV()//lret := startjob("U_ ENVSITPV",getenvserver(),.F.,,.F.)   //Envia interface de alteração de situação do pedido atual
		  Else
		     SC5->( MSUnLock() )
		  EndIf
       EndIf
  	Else
        //Registra problema com pedido
		If !SC5->( DBSeek( xFilial("SC5") + _cNumPed ) )
		   aAdd(_alista,{_cNumPed, "Pedido foi EXCLUIDO antes do processamento"})
		ElseIf !Empty(SC5->C5_NOTA) 
           aAdd(_alista,{_cNumPed, "Pedido foi FATURADO antes do processamento"})
		ElseIf SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. (!Empty(SC9->C9_CARGA) .Or. !Empty(SC9->C9_NFISCAL) )
           aAdd(_alista,{_cNumPed, "Pedido CARREGADO antes do processamento"})
     	EndIf
     EndIf
		
	 SC5->( DBSkip() )
Next 

If Len(_alista) > 0
	U_ITListBox( "Pedidos com alteração de produto" , {"Numero","Situacao"} , _alista , .T. , 1 )
EndIf
	
//Atualiza tela
FWMsgRun( , {|oproc| AOMS109ARQ(oproc) }, "Aguarde!" , 'Carregando dados...' )
	
Return

/*
===============================================================================================================================
Programa----------: AOMS109CH
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Carrega produtos com mesmo código de barras para função de alteração
Parametros--------: _Cprod - string com código e descrição do produto selecionado
					_ntipo - 1 - origem/destino, 2 - origem
Retorno-----------: array com produtos similares
===============================================================================================================================
*/
Static Function AOMS109CH(_cprod,_ntipo)

Local _aOrd := SaveOrd({"SB1"})
Local _aitens := {_cprod}  , _nni
Local _cListaProd := ""

Default _ntipo := 1

SB1->(DBSetOrder(1))
If SB1->(DBSeek(xFilial("SB1")+_cprod))
   _cListaProd := SB1->B1_I_PRDSM
EndIf

If Select("SC52") <> 0
   SC52->( DBCloseArea() )
EndIf

_cQuery := " SELECT B1_COD,B1_DESC,B1_CODBAR "
_cQuery += " FROM  "+ RetSqlName('SB1') +' B1 '
_cQuery += " WHERE	B1.D_E_L_E_T_ = ' ' AND B1_TIPO = 'PA' AND B1_MSBLQL <> '1' "
If !Empty(_cListaProd)
   _cQuery += " AND (B1_COD IN "  + FormatIn( _cListaProd , ";" ) + " OR (B1.B1_CODBAR > ' ' AND B1.B1_CODBAR = (SELECT B12.B1_CODBAR FROM "+ RetSqlName('SB1') +' B12  '
   _cQuery += " WHERE	B12.D_E_L_E_T_ = ' ' AND B12.B1_COD = '" + SubStr(_cprod,1,11) + "' AND B12.B1_COD <> B1.B1_COD))) "
Else
   _cQuery += " AND B1.B1_CODBAR > ' ' AND B1.B1_CODBAR = (SELECT B12.B1_CODBAR FROM "+ RetSqlName('SB1') +' B12  '
   _cQuery += " WHERE	B12.D_E_L_E_T_ = ' ' AND B12.B1_COD = '" + SubStr(_cprod,1,11) + "' AND B12.B1_COD <> B1.B1_COD) "
EndIf
_cQuery += " ORDER BY B1.B1_COD "

MPSysOpenQuery( _cQuery , "QRYCABEC2")

DBSelectArea("QRYCABEC2")
	
QRYCABEC2->( DBGoTop() )

_lprim := .T.
		
While QRYCABEC2->( !Eof() )

	If _lprim
		_aitens := {}
		_lprim := .F.
	EndIf
	
	aAdd(_aitens,QRYCABEC2->B1_COD + " - " + QRYCABEC2->B1_DESC )
	QRYCABEC2->( DBSkip() )
	
EndDo

If _ntipo == 1

	_ocompd:aitems := _aitens
	_acompd := _aitens

	For _nni := 1 To Len(_ocompd:aitems)

		If _acompd[_nni] == _acomps[_ocomps:nat]
	
			_ocompd:select(_nni)
		
		EndIf

	Next
	
EndIf

RestOrd(_aOrd)

Return _aitens

/*
===============================================================================================================================
Função------------: AOMS109EA
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Altera produto do pedido de vendas.
Parametros--------: Nenhum
Retorno-----------: True or False
===============================================================================================================================
*/
Static Function AOMS109EA()
  
Local _aCabcPVEx	:= {}
Local _aItenPVEx	:= {}
Local _lalt         := .F.
		
SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
		
   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->C5_FILIAL+SC5->C5_NUM 

   		If AllTrim(SC6->C6_PRODUTO) == SubStr(_acomps[_ocomps:nat],1,11)
   		
   			_cproduto := SubStr(_acompd[_ocompd:nat],1,11)
   			_lalt := .T.
   			
   		Else
   		
   			_cproduto := SC6->C6_PRODUTO
   			
   		EndIf

         aAdd( _aItenPVEx , {	{ "C6_FILIAL"  , SC6->C6_FILIAL	,Nil},; 
								{ "C6_ITEM"    , SC6->C6_ITEM	,Nil},;
								{ "C6_PRODUTO" , _cproduto      ,Nil},;
								{ "C6_LOCAL"   , SC6->C6_LOCAL	,Nil},;
								{ "C6_QTDVEN"  , SC6->C6_QTDVEN	,Nil},;
								{ "C6_UM"      , SC6->C6_UM		,Nil},;
								{ "C6_PRCVEN"  , SC6->C6_PRCVEN	,Nil},;
								{ "C6_VALOR"   , SC6->C6_VALOR	,Nil},;
								{ "C6_PEDCLI"  , SC6->C6_PEDCLI	,Nil},;
								{ "C6_QTDLIB"  , SC6->C6_QTDLIB	,Nil},;
								{ "C6_NUM"     , SC6->C6_NUM	,Nil}})
  	
	  SC6->( DBSkip() )
   EndDo
		
   //================================================================================
   // Prepara arrays de cabeçalhos dos pedidos
   //================================================================================
   _aCabcPVEx := {		{ "C5_FILIAL"  , SC5->C5_FILIAL   	  ,Nil},;
						{ "C5_NUM"     , SC5->C5_NUM       	  ,Nil},;
						{ "C5_TIPO"    , SC5->C5_TIPO    	  ,Nil},;
						{ "C5_CLIENTE" , SC5->C5_CLIENTE 	  ,Nil},;
						{ "C5_LOJACLI" , SC5->C5_LOJACLI 	  ,Nil},;
						{ "C5_CLIENT " , SC5->C5_CLIENT  	  ,Nil},; // Codigo do cliente
						{ "C5_LOJAENT" , SC5->C5_LOJAENT 	  ,Nil},; // Loja para entrada
						{ "C5_TIPOCLI" , SC5->C5_TIPOCLI 	  ,Nil},;
						{ "C5_CONDPAG" , SC5->C5_CONDPAG 	  ,Nil},;
						{ "C5_VEND1"   , SC5->C5_VEND1   	  ,Nil},;
						{ "C5_EMISSAO" , SC5->C5_EMISSAO      ,Nil},;
						{ "C5_TPFRETE" , SC5->C5_TPFRETE 	  ,Nil},;
						{ "C5_VOLUME1" , SC5->C5_VOLUME1 	  ,Nil},;
						{ "C5_ESPECI1" , SC5->C5_ESPECI1 	  ,Nil},;
						{ "C5_TPCARGA" , SC5->C5_TPCARGA 	  ,Nil},;
						{ "C5_I_AGEND" , SC5->C5_I_AGEND 	  ,Nil},;
						{ "C5_I_ENVRD" , "N"                  ,Nil},;							
				  		{ "C5_I_IDPED" , SC5->C5_I_IDPED	  ,Nil} }  
		
	//=======================================================================================================
	// Caso outro usuario exclua, fature ou bloqueie o Pedido de Venda posteriormente ao usuario ter 
	// clicado no botao ok da exclusao
	//========================================================================================================
	If Empty(SC5->C5_NOTA) .And. Empty(SC5->C5_BLQ) 
   	   //Para que a exclusao no siga auto seja executada em modo exclusivo e nao esteja locado por outro usuario o pedido de venda ocrrente
	   SC5->(RecLock("SC5"),.F.)	
            
	   _lOK_RDC := .T.
	   If SC5->C5_I_ENVRD = "S"
	      If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms 
             FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS094E(P)} , 'Aguarde!' , 'Enviando para o RDC o cancelamento do Pedido Remessa...') 
		  Else
             FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS140E(P,.T.)} , 'Aguarde!' , 'Enviando para o TMS Multi-Embarcador o cancelamento do Pedido Remessa...') 
		  EndIf 
       EndIf

       _lExclParcial := .T.
       
	   If _lOK_RDC .And. _lalt

	   		lMsErroAuto := .F.
	   		MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVEx , _aItenPVEx , 4 )  
		
	   EndIf
			
	   SC5->( MSUnLock() )
		
	   If !_lalt
	 			
	   		aAdd(_alista,{SC5->C5_NUM, "Pedido " + SC5->C5_NUM + " não tem produtos selecionados para alteração!"})
	   		
	   Else
			
	     If lMsErroAuto .Or. !_lOK_RDC

	     _cErro:="["+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"Mata410.LOG")+"]"
	     _cErro:= StrTran(_cErro,chr(13)," ")
	     _cErro:= StrTran(_cErro,chr(10)," ") //Tira CRs da string para o itlist mostrar todo o erro
		 If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms
		    aAdd(_alista,{SC5->C5_NUM, IIf(_lOK_RDC,"Erro ao alterar Pedido " + SC5->C5_NUM + " no Protheus - " + _cErro,"Erro ao excluir Pedido " + SC5->C5_NUM + " no RDC!")})
		 Else
            aAdd(_alista,{SC5->C5_NUM, IIf(_lOK_RDC,"Erro ao alterar Pedido " + SC5->C5_NUM + " no Protheus - " + _cErro,"Erro ao excluir Pedido " + SC5->C5_NUM + " no TMS Multi-Embarcador!")})
		 EndIf  
			
	     Else

		 aAdd(_alista,{SC5->C5_NUM, "Pedido " + SC5->C5_NUM + " alterado com sucesso!"})
		  
	     _cMsg      := "Monitor alteração da logistica no pedido de vendas, do produto"  + SubStr(_acomps[_ocomps:nat],1,11) + " para o produto " +  SubStr(_acompd[_ocompd:nat],1,11) 
	      
          _cCodOper  := "007"
          _dDataOper := Date()
          _cEncer    := "N"
                 
          U_GrvMonitor(SC5->C5_FILIAL,SC5->C5_NUM,_cCodOper,_cMsg,_cEncer,_dDataOper,_dDataOper,_dDataOper) 
          
         EndIf
         
       EndIf
    
    Else
       
    	_cMsg := "Pedido " + SC5->C5_NUM + " foi faturado ou bloqueado antes do processamento!"
    	lMsErroAuto := .T.
    
    EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS109CT()
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/10/2018
Descrição---------: Corte de produtos bloqueados
Parametros--------: oproc - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109CT(oproc)

Local _lbloqi := .F.
Local _aLstPedV := {}
Local _nI 


Private lMsErroAuto	:= .F.
Private _alista3 := {}    
Private _alistak := {}                    

//=====================================================================
// Retorna Array com filil, nr PV e Recno Pv selecionados pelo usuário.
//=====================================================================
_aLstPedV  := RetSelecPV() 

//==================================
// Se não tem registros já retorna
//==================================
If Empty(_aLstPedV)	 // Empty(_cNumPed)
   U_ITMsg("Nenhum registro com bloqueio de estoque selecionado","Atenção","Selecione ao menos um registro com legenda azul de bloqueio de estoque",1)
   TRBF->(DBGoTop())
   Return
EndIf

//================================================================================
// Percorre os pedidos selecionados e monta o cabecalho e itens do pedido de venda
//================================================================================
_npv := 0
_alista := {}
SC5->(DBSetOrder(1))
SA1->(DBSetOrder(1))
SC9->(DBSetOrder(1))
	
For _nI := 1 To Len(_aLstPedV )	

    SC5->(DBGoTo(_aLstPedV[_nI,3]))

	_cNumPed := SC5->C5_NUM         
	_npv++
		
	//Atualiza régua
	oproc:cCaption := ("Analisando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	ProcessMessages()
		
	If SC9->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
	   _lbloqi := .F.
			
	   While SC9->C9_FILIAL == SC5->C5_FILIAL .And. SC9->C9_PEDIDO == SC5->C5_NUM
		  If !Empty(SC9->C9_BLEST) .And.  AllTrim(SC9->C9_PRODUTO) == SubStr(_acomps[_ocomps:nat],1,11)
		     //Valida bloqueio logístico
			 If SC5->C5_I_BLOG == "S"
			 	//Verifica permissão de ajuste de bloqueio logístico
				ZZL->(DBSetOrder(3))
				If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"
                   aAdd(_alistaK,{SC5->C5_NUM,;
					     		  SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+" - " + SubStr(SC5->C5_I_NOME,1,45),;
								  AllTrim(SC9->C9_PRODUTO) + " - " + SubStr(Posicione("SB1",1,xFilial("SB1")+AllTrim(SC9->C9_PRODUTO),"B1_DESC"),1,45),SC9->C9_QTDLIB,"Em Planej. Logístico" })
				Else
      			   aAdd(_alistaK,{SC5->C5_NUM,;
								  SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+" - " + SubStr(SC5->C5_I_NOME,1,45),;
								  AllTrim(SC9->C9_PRODUTO) + " - " + SubStr(Posicione("SB1",1,xFilial("SB1")+AllTrim(SC9->C9_PRODUTO),"B1_DESC"),1,45),SC9->C9_QTDLIB,"Ok para corte" })
		
				   aAdd(_alista3,{SC5->C5_NUM,;
								  SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+" - " + SubStr(SC5->C5_I_NOME,1,45),;
								  AllTrim(SC9->C9_PRODUTO) + " - " + SubStr(Posicione("SB1",1,xFilial("SB1")+AllTrim(SC9->C9_PRODUTO),"B1_DESC"),1,45),SC9->C9_QTDLIB })

				EndIf
			 Else
			    aAdd(_alistaK,{SC5->C5_NUM,;
							  SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+" - " + SubStr(SC5->C5_I_NOME,1,45),;
							  AllTrim(SC9->C9_PRODUTO) + " - " + SubStr(Posicione("SB1",1,xFilial("SB1")+AllTrim(SC9->C9_PRODUTO),"B1_DESC"),1,45),SC9->C9_QTDLIB,"Ok para corte" })
		
				aAdd(_alista3,{SC5->C5_NUM,;
							  SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+" - " + SubStr(SC5->C5_I_NOME,1,45),;
							  AllTrim(SC9->C9_PRODUTO) + " - " + SubStr(Posicione("SB1",1,xFilial("SB1")+AllTrim(SC9->C9_PRODUTO),"B1_DESC"),1,45),SC9->C9_QTDLIB })
			 EndIf
		  EndIf
				
		  SC9->(DBSkip())
	   EndDo
	EndIf 
Next
If Len(_alista3) == 0

	U_ITMsg("Não foram localizados produtos válidos com bloqueio de estoque para corte","Atenção","Atualize a tela para buscar status atual dos pedidos",1)
	
Else

	If U_ITListBox( "Pedidos que sofrerão corte de produtos" , {"Pedido","Cliente","Produto","Quantidade","Situação"} , _alistak , .T. , 1 )
	
		FWMsgRun(,{|oproc|, AOMS109EX8(_alista3,oproc)},"Aguarde...","Realizando corte de produto nos pedidos de vendas...")
		
	Else
	
		U_ITMsg("Processo cancelado","Atenção",,1)
		
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS109EX8()
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/10/2018
Descrição---------: Execução de corte de produtos bloqueados
Parametros--------: _alista - array com pedidos e produtos a serem cortados
					oproc - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109EX8(_alista,oproc)

Local _cErro := Space(200)  //, _nnj
Local _ntot := 0
Local _aLstPedV := {}
Local _nI 

Private _alista2 := {}
Private _lexclui := .T.

//=================================================================
// Retorna um array com filia, Nr.PV e Recno dos PVs selecionados.
//=================================================================
_aLstPedV  := RetSelecPV() 

//=================================
// Se não tem registros já retorna
//=================================
If Empty(_aLstPedV)	 // Empty(_cNumPed)
   U_ITMsg("Nenhum registro selecionado","Atenção",,1)
   TRBF->(DBGoTop())
   Return
EndIf
	
//================================================================================
// Percorre os pedidos selecionados e monta o cabecalho e itens do pedido de venda
//================================================================================
_npv := 0
_alista2 := {}
nQtdTit := Len(_alista)
SC5->(DBSetOrder(1))
SA1->(DBSetOrder(1))
SC9->(DBSetOrder(1))

For _nI := 1 To Len(_aLstPedV )	

    SC5->(DBGoTo(_aLstPedV[_nI,3]))

    _cNumPed := SC5->C5_NUM         
	_npv++
		
	//Atualiza régua
	oproc:cCaption := ("Processando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	ProcessMessages()
		
	_aAreaCabec := SC5->( FWGetArea() )

	//=======================================================================================================
	// Caso outro usuario exclua, fature ou carregue o Pedido de Venda posteriormente ao usuario ter 
	// filtrado os dados
	//========================================================================================================
	If Empty(SC5->C5_NOTA)  .AND.((( SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. Empty(SC9->C9_CARGA) .And. Empty(SC9->C9_NFISCAL) )).OR. !( SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM))))
	   //Grava se o pedido tem liberação de estoque		
	   If SC9->C9_FILIAL == SC5->C5_FILIAL .And. SC9->C9_PEDIDO == SC5->C5_NUM
		  _ltemlib := .T.
	   Else
		  _ltemlib := .F.
	   EndIf
			
	   oproc:cCaption := ("Cortando produtos para PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(_ntot,6) +"]")
	   ProcessMessages()
            
  	   lMsErroAuto := .F.
       AOMS109E2(_alista)//CORTA PRODUTO DO PEDIDO DE VENDAS
						
	   If lMsErroAuto 
		  _cErro := "Erro ao cortar produto do PV: "
	      _cErro += "["+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"Mata410.LOG")+"]"
		  aAdd(_alista2,{SC5->C5_NUM,_cErro})
 	   Else
		  //Se tinha liberação de estoque refaz a liberação
		  If _ltemlib .And. !_lexclui //Só libera se não excluiu o pedido todo
		     oproc:cCaption := ("Liberando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
			 ProcessMessages()
             _cmsglibpv := AOMS109LP(oproc)//faz liberação de estoque para o item de pedido de vendas
				   
			 If !Empty(_cmsglibpv) 
		   		_cErro:="Erro ao liberar o PV: "
		   		_cErro+=_cmsglibpv
		   		aAdd(_alista2,{SC5->C5_NUM,_cErro})
			 EndIf
		  EndIf
		  
		  If SC5->C5_I_ENVRD = 'S'
             oproc:cCaption := ("Enviando Status TMS do PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
 
             ProcessMessages()
			 U_ENVSITPV()//lret := startjob("U_ ENVSITPV",getenvserver(),.F.,,.F.)   //Envia interface de alteração de situação do pedido atual
          Else
			 SC5->( MSUnLock() )
		  EndIf
	   EndIf
	Else
	   _npv++
    	//Registra problema com pedido
		If !SC5->( DBSeek( xFilial("SC5") + _cNumPed ) )
		   aAdd(_alista,{_cNumPed, "Pedido foi EXCLUIDO antes do processamento"})
		ElseIf !Empty(SC5->C5_NOTA) 
		   aAdd(_alista,{_cNumPed, "Pedido foi FATURADO antes do processamento"})
		ElseIf SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. (!Empty(SC9->C9_CARGA) .Or. !Empty(SC9->C9_NFISCAL) )
 		   aAdd(_alista,{_cNumPed, "Pedido CARREGADO antes do processamento"})
	    EndIf
	 EndIf
   Next 

If Len(_alista2) > 0
	U_ITListBox( "Pedidos com corte de produto" , {"Numero","Situacao"} , _alista2 , .T. , 1 )
Else
	U_ITMsg("Nenhuma alteração realizada","Atenção",,1)
EndIf

//Atualiza tela
FWMsgRun( , {|oproc| AOMS109ARQ(oproc) }, "Aguarde!" , 'Carregando dados...' )

Return

/*
===============================================================================================================================
Função------------: AOMS109E2
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Corta produto do pedido de vendas.
Parametros--------: _alista - array com pedidos e produtos a cortar
Retorno-----------: True or False
===============================================================================================================================
*/
Static Function AOMS109E2(_alista)
  
Local _aItensPV		:= {}
Local _aItensig		:= {}
Local _aCabcPVRe    := {}
Local _aItenPVRe    := {}
Local _nRecnoSC5    := 0
Local _nOrderSC5    := 0

_lexclui    := .T.
		
SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
_cprods := ""
		
   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->C5_FILIAL+SC5->C5_NUM 

   		_nposi := aScan(_alista,{|item|, AllTrim(SubStr(item[3],1,11)) == AllTrim(SC6->C6_PRODUTO) .And. AllTrim(item[1]) == AllTrim(SC5->C5_NUM)  })
   		
   		
   		
   		If _nposi > 0
   			_cDeleta := "S"
   		Else
   			_cDeleta := "N"
   			_lexclui := .F.
   		EndIf
   		
   	  _aItemPV:={}
	  aAdd( _aItemPV , { "LINPOS"     ,"C6_ITEM", SC6->C6_ITEM }) //  Informa a posição do item
      aAdd( _aItemPV , { "AUTDELETA"  ,_cDeleta        , Nil }) // Informa se o item será ou não excluído.
	  aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
	  aAdd( _aItemPV , { "C6_NUM"     ,SC6->C6_NUM     , Nil }) // Num. Pedido
	  aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
	  aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
	  aAdd( _aItemPV , { "C6_QTDVEN"  ,SC6->C6_QTDVEN         , Nil }) // Quantidade Vendida
	  aAdd( _aItemPV , { "C6_UNSVEN"  ,SC6->C6_UNSVEN        , Nil }) // Quantidade Vendida 2 un
	  aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
	  aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
	  aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
	  aAdd( _aItemPV , { "C6_LOJA"    ,SC6->C6_LOJA	   , Nil })
	  aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
	  aAdd( _aItemPV , { "C6_VALOR"   ,SC6->C6_VALOR, Nil }) // valor total do item // SC6->C6_VALOR
	  aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
	  aAdd( _aItemPV , { "C6_TES"     ,SC6->C6_TES     , Nil })
	  aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
	  aAdd( _aItemPV , { "C6_CF"      ,SC6->C6_CF	  , Nil })
	  aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
	  aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
	  aAdd( _aItemPV , { "C6_PEDCLI"  ,SC6->C6_PEDCLI  , Nil })
	  aAdd( _aItemPV , { "C6_I_BLPRC" ,SC6->C6_I_BLPRC , Nil })
      aAdd( _aItemPV , { "C6_I_QPALT" ,SC6->C6_I_QPALT, Nil }) // Quantidade de Pallets
      aAdd( _aItemPV,  { "C6_I_USER "    ,SC6->C6_I_USER , Nil})
      aAdd( _aItemPV,  { "C6_I_LIBPC"    ,SC6->C6_I_LIBPC, Nil})
      aAdd( _aItemPV,  { "C6_I_DLIBP"    ,SC6->C6_I_DLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_PLIBP"    ,SC6->C6_I_PLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_ULIBP"    ,SC6->C6_I_ULIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_VLIBP"    ,SC6->C6_I_VLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_MOTLP"    ,SC6->C6_I_MOTLP, Nil})
      aAdd( _aItemPV,  { "C6_I_QTLIP"    ,SC6->C6_I_QTLIP, Nil})
      aAdd( _aItemPV,  { "C6_I_CLILP"    ,SC6->C6_I_CLILP, Nil})
      aAdd( _aItemPV,  { "C6_I_CLILB"    ,SC6->C6_I_CLILB, Nil})
      aAdd( _aItemPV,  { "C6_I_VLIBB"    ,SC6->C6_I_VLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_QLIBB"    ,SC6->C6_I_QLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_LLIBP"    ,SC6->C6_I_LLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_LLIBB"    ,SC6->C6_I_LLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_MOTLB"    ,SC6->C6_I_MOTLB, Nil})
      aAdd( _aItemPV,  { "C6_I_PLIBB"    ,SC6->C6_I_PLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_DLIBB"    ,SC6->C6_I_DLIBB, Nil})
      aAdd( _aItemPV,  { "C6_COMIS1"     ,SC6->C6_COMIS1, Nil})
      aAdd( _aItemPV,  { "C6_COMIS2"     ,SC6->C6_COMIS2, Nil})
      aAdd( _aItemPV,  { "C6_COMIS3"     ,SC6->C6_COMIS3, Nil})
            
      _aItemPI:={}
	  aAdd( _aItemPI , { "LINPOS"     ,"C6_ITEM", SC6->C6_ITEM }) //  Informa a posição do item
      aAdd( _aItemPI , { "AUTDELETA"  ,"N"        , Nil }) // Informa se o item será ou não excluído.
	  aAdd( _aItemPI , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
	  aAdd( _aItemPI , { "C6_NUM"     ,SC6->C6_NUM     , Nil }) // Num. Pedido
	  aAdd( _aItemPI , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
	  aAdd( _aItemPI , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
	  aAdd( _aItemPI , { "C6_UNSVEN"  ,SC6->C6_UNSVEN        , Nil }) // Quantidade Vendida 2 un
	  aAdd( _aItemPI , { "C6_QTDVEN"  ,SC6->C6_QTDVEN         , Nil }) // Quantidade Vendida
	  aAdd( _aItemPI , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
	  aAdd( _aItemPI , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
	  aAdd( _aItemPI , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
	  aAdd( _aItemPI , { "C6_LOJA"    ,SC6->C6_LOJA	   , Nil })
	  aAdd( _aItemPI , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
	  aAdd( _aItemPI , { "C6_VALOR"   ,SC6->C6_VALOR, Nil }) // valor total do item // SC6->C6_VALOR
	  aAdd( _aItemPI , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
	  aAdd( _aItemPI , { "C6_TES"     ,SC6->C6_TES     , Nil })
	  aAdd( _aItemPI , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
	  aAdd( _aItemPI , { "C6_CF"      ,SC6->C6_CF	  , Nil })
	  aAdd( _aItemPI , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
	  aAdd( _aItemPI , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
	  aAdd( _aItemPI , { "C6_PEDCLI"  ,SC6->C6_PEDCLI  , Nil })
	  aAdd( _aItemPI , { "C6_I_BLPRC" ,SC6->C6_I_BLPRC , Nil })
      aAdd( _aItemPI , { "C6_I_QPALT" ,SC6->C6_I_QPALT, Nil }) // Quantidade de Pallets
      aAdd( _aItemPI,  { "C6_I_USER "    ,SC6->C6_I_USER , Nil})
      aAdd( _aItemPI,  { "C6_I_LIBPC"    ,SC6->C6_I_LIBPC, Nil})
      aAdd( _aItemPI,  { "C6_I_DLIBP"    ,SC6->C6_I_DLIBP, Nil})
      aAdd( _aItemPI,  { "C6_I_PLIBP"    ,SC6->C6_I_PLIBP, Nil})
      aAdd( _aItemPI,  { "C6_I_ULIBP"    ,SC6->C6_I_ULIBP, Nil})
      aAdd( _aItemPI,  { "C6_I_VLIBP"    ,SC6->C6_I_VLIBP, Nil})
      aAdd( _aItemPI,  { "C6_I_MOTLP"    ,SC6->C6_I_MOTLP, Nil})
      aAdd( _aItemPI,  { "C6_I_QTLIP"    ,SC6->C6_I_QTLIP, Nil})
      aAdd( _aItemPI,  { "C6_I_CLILP"    ,SC6->C6_I_CLILP, Nil})
      aAdd( _aItemPI,  { "C6_I_CLILB"    ,SC6->C6_I_CLILB, Nil})
      aAdd( _aItemPI,  { "C6_I_VLIBB"    ,SC6->C6_I_VLIBB, Nil})
      aAdd( _aItemPI,  { "C6_I_QLIBB"    ,SC6->C6_I_QLIBB, Nil})
      aAdd( _aItemPI,  { "C6_I_LLIBP"    ,SC6->C6_I_LLIBP, Nil})
      aAdd( _aItemPI,  { "C6_I_LLIBB"    ,SC6->C6_I_LLIBB, Nil})
      aAdd( _aItemPI,  { "C6_I_MOTLB"    ,SC6->C6_I_MOTLB, Nil})
      aAdd( _aItemPI,  { "C6_I_PLIBB"    ,SC6->C6_I_PLIBB, Nil})
      aAdd( _aItemPI,  { "C6_I_DLIBB"    ,SC6->C6_I_DLIBB, Nil})
      aAdd( _aItemPI,  { "C6_COMIS1"     ,SC6->C6_COMIS1, Nil})
      aAdd( _aItemPI,  { "C6_COMIS2"     ,SC6->C6_COMIS2, Nil})
      aAdd( _aItemPI,  { "C6_COMIS3"     ,SC6->C6_COMIS3, Nil})
      
            
      aAdd( _aItensPV ,_aItemPV )                      
      
      aAdd( _aItensig ,_aItemPI )  
			
	  SC6->( DBSkip() )
   
   EndDo
		
   //================================================================================
   // Prepara arrays de cabeçalhos dos pedidos
   //================================================================================
   _aCabPV := {}
   aAdd( _aCabPV, { "C5_FILIAL"	    ,SC5->C5_FILIAL  , Nil}) //filial
   aAdd( _aCabPV, { "C5_NUM"        ,SC5->C5_NUM	 , Nil}) 
   aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil}) //Tipo de pedido
   aAdd( _aCabPV, { "C5_I_OPER"	    ,SC5->C5_I_OPER  , Nil}) //Tipo da operacao
   aAdd( _aCabPV, { "C5_CLIENTE"    ,SC5->C5_CLIENTE , NiL}) //Codigo do cliente
   aAdd( _aCabPV, { "C5_CLIENT"     ,SC5->C5_CLIENT	 , Nil}) 
   aAdd( _aCabPV, { "C5_LOJAENT"    ,SC5->C5_LOJAENT , NiL}) //Loja para entrada
   aAdd( _aCabPV, { "C5_LOJACLI"    ,SC5->C5_LOJACLI , NiL}) //Loja do cliente
   aAdd( _aCabPV, { "C5_EMISSAO"    ,SC5->C5_EMISSAO , NiL}) //Data de emissao
   aAdd( _aCabPV, { "C5_TRANSP"     ,SC5->C5_TRANSP	 , Nil}) 
   aAdd( _aCabPV, { "C5_CONDPAG"    ,SC5->C5_CONDPAG , NiL}) //Codigo da condicao de pagamanto*
   aAdd( _aCabPV, { "C5_VEND1"      ,SC5->C5_VEND1	 , Nil}) 
   aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil}) //Moeda
   aAdd( _aCabPV, { "C5_MENPAD"     ,SC5->C5_MENPAD	 , Nil}) 
   aAdd( _aCabPV, { "C5_LIBEROK"    ,SC5->C5_LIBEROK , NiL}) //Liberacao Total
   aAdd( _aCabPV, { "C5_TIPLIB"     ,SC5->C5_TIPLIB  , Nil}) //Tipo de Liberacao
   aAdd( _aCabPV, { "C5_TIPOCLI"    ,SC5->C5_TIPOCLI , NiL}) //Tipo do Cliente
   aAdd( _aCabPV, { "C5_I_NPALE"    ,SC5->C5_I_NPALE , NiL}) //Numero que originou a pedido de palete
   aAdd( _aCabPV, { "C5_I_PEDPA"    ,SC5->C5_I_PEDPA , NiL}) //Pedido Refere a um pedido de Pallet
   aAdd( _aCabPV, { "C5_I_DTENT"    ,SC5->C5_I_DTENT , Nil}) //Dt de Entrega // SC5->C5_I_DTENT
   aAdd( _aCabPV, { "C5_I_TRCNF"    ,SC5->C5_I_TRCNF , Nil})
   aAdd( _aCabPV, { "C5_I_OBCOP" 	,SC5->C5_I_OBCOP , Nil})
   aAdd( _aCabPV, { "C5_I_OBPED" 	,SC5->C5_I_OBPED , Nil})
   aAdd( _aCabPV, { "C5_I_BLPRC"    ,SC5->C5_I_BLPRC , Nil})
   aAdd( _aCabPV, { "C5_I_BLCRE"    ,SC5->C5_I_BLCRE , Nil})
   aAdd( _aCabPV, { "C5_I_FILFT"    ,SC5->C5_I_FILFT , Nil})
   aAdd( _aCabPV, { "C5_I_FLFNC"    ,SC5->C5_I_FLFNC , Nil})
   aAdd( _aCabPV, { "C5_I_BLCRE"    ,SC5->C5_I_BLCRE , Nil})
   aAdd( _aCabPV, { "C5_I_TIPCA"    ,SC5->C5_I_TIPCA , Nil})
   aAdd( _aCabPV, { "C5_MENNOTA"    ,SC5->C5_MENNOTA , Nil})
   aAdd( _aCabPV, { "C5_MENPAD"     ,SC5->C5_MENPAD  , Nil})
   aAdd( _aCabPV, { "C5_I_BLPRC"    ,SC5->C5_I_BLPRC, Nil}) 
   aAdd( _aCabPV, { "C5_I_DTLIB"    ,SC5->C5_I_DTLIB, Nil})
   aAdd( _aCabPV, { "C5_I_IDPED"    ,SC5->C5_I_IDPED, Nil})
   aAdd( _aCabPV, { "C5_ORIGEM "    ,SC5->C5_ORIGEM , Nil})
   aAdd( _aCabPV, { "C5_I_DTAIM"    ,SC5->C5_I_DTAIM, Nil})
   aAdd( _aCabPV, { "C5_I_HORAI"    ,SC5->C5_I_HORAI, Nil})
   aAdd( _aCabPV, { "C5_I_DATAA"    ,SC5->C5_I_DATAA, Nil})
   aAdd( _aCabPV, { "C5_I_HORAA"    ,SC5->C5_I_HORAA, Nil})
   aAdd( _aCabPV, { "C5_I_DTLIP"    ,SC5->C5_I_DTLIP, Nil})
   aAdd( _aCabPV, { "C5_I_MLIBP"    ,SC5->C5_I_MLIBP, Nil})
   aAdd( _aCabPV, { "C5_I_DTAVA"    ,SC5->C5_I_DTAVA, Nil})
   aAdd( _aCabPV, { "C5_I_HRAVA"    ,SC5->C5_I_HRAVA, Nil})
   aAdd( _aCabPV, { "C5_I_USRAV"    ,SC5->C5_I_USRAV, Nil})
   aAdd( _aCabPV, { "C5_I_LIBCA"    ,SC5->C5_I_LIBCA, Nil})
   aAdd( _aCabPV, { "C5_I_LIBCT"    ,SC5->C5_I_LIBCT, Nil})
   aAdd( _aCabPV, { "C5_I_LIBL "    ,SC5->C5_I_LIBL , Nil})
   aAdd( _aCabPV, { "C5_I_LIBCV"    ,SC5->C5_I_LIBCV, Nil}) //49 valor liberado de crédito
   aAdd( _aCabPV, { "C5_I_LIBCD"    ,SC5->C5_I_LIBCD, Nil})
   aAdd( _aCabPV, { "C5_I_BLCRE"    ,SC5->C5_I_BLCRE, Nil})
   aAdd( _aCabPV, { "C5_I_MOTBL"    ,SC5->C5_I_MOTBL, Nil})
   aAdd( _aCabPV, { "C5_I_DTLIC"    ,SC5->C5_I_DTLIC, Nil})
   aAdd( _aCabPV, { "C5_I_PLIBP"    ,SC5->C5_I_PLIBP, Nil})
   aAdd( _aCabPV, { "C5_I_ULIBP"    ,SC5->C5_I_ULIBP, Nil}) 
   aAdd( _aCabPV, { "C5_I_VLIBP"    ,SC5->C5_I_VLIBP, Nil})//56 valor liberado de preço
   aAdd( _aCabPV, { "C5_I_MOTLP"    ,SC5->C5_I_MOTLP, Nil})
   aAdd( _aCabPV, { "C5_I_MOTLB"    ,SC5->C5_I_MOTLB, Nil})
   aAdd( _aCabPV, { "C5_I_QLIBP"    ,SC5->C5_I_QLIBP, Nil}) //59 TOTAL liberado de preço
   aAdd( _aCabPV, { "C5_I_VLIBB"    ,SC5->C5_I_VLIBB, Nil})//60 valor liberado de bonificação
   aAdd( _aCabPV, { "C5_I_QLIBB"    ,SC5->C5_I_QLIBB, Nil})
   aAdd( _aCabPV, { "C5_I_CLILP"    ,SC5->C5_I_CLILP, Nil})
   aAdd( _aCabPV, { "C5_I_CLILB"    ,SC5->C5_I_CLILB, Nil})
   aAdd( _aCabPV, { "C5_I_LLIBB"    ,SC5->C5_I_LLIBB, Nil})
   aAdd( _aCabPV, { "C5_I_ULIBB"    ,SC5->C5_I_ULIBB, Nil})
   aAdd( _aCabPV, { "C5_I_LLIBP"    ,SC5->C5_I_LLIBP, Nil})
   aAdd( _aCabPV, { "C5_I_HLIBP"    ,SC5->C5_I_HLIBP, Nil})
   aAdd( _aCabPV, { "C5_I_FILOR"    ,SC5->C5_I_FILOR, Nil})
   aAdd( _aCabPV, { "C5_I_PEDOR"    ,SC5->C5_I_PEDOR, Nil})
   aAdd( _aCabPV, { "C5_I_DTRAN"    ,SC5->C5_I_DTRAN, Nil})
   aAdd( _aCabPV, { "C5_I_UTRAN"    ,SC5->C5_I_UTRAN, Nil})
   aAdd( _aCabPV, { "C5_I_MTRAN"    ,SC5->C5_I_MTRAN, Nil})
   aAdd( _aCabPV, { "C5_I_HORP "    ,SC5->C5_I_HORP , Nil})
   aAdd( _aCabPV, { "C5_I_AGEND"    ,SC5->C5_I_AGEND, Nil})
   aAdd( _aCabPV, { "C5_I_CHPCL"    ,SC5->C5_I_CHPCL, Nil})
   aAdd( _aCabPV, { "C5_I_DOCA "    ,SC5->C5_I_DOCA , Nil})
   aAdd( _aCabPV, { "C5_I_TRCNF"    ,SC5->C5_I_TRCNF, Nil})
   aAdd( _aCabPV, { "C5_I_FLFNC"    ,SC5->C5_I_FLFNC, Nil})
   aAdd( _aCabPV, { "C5_I_OBSAV"    ,SC5->C5_I_OBSAV, Nil})
   aAdd( _aCabPV, { "C5_I_FILFT"    ,SC5->C5_I_FILFT, Nil})
   aAdd( _aCabPV, { "C5_I_PDFT "    ,SC5->C5_I_PDFT , Nil})
   aAdd( _aCabPV, { "C5_I_PDPR "    ,SC5->C5_I_PDPR , Nil})  
   aAdd( _aCabPV, { "C5_TPFRETE"    ,SC5->C5_TPFRETE, Nil})
   
   _clocmot := _cmotivs
		
	//=======================================================================================================
	// Caso outro usuario exclua, fature ou bloqueie o Pedido de Venda posteriormente ao usuario ter 
	// clicado no botao ok da exclusao
	//========================================================================================================
	If Empty(SC5->C5_NOTA) .And. Empty(SC5->C5_BLQ) 
   	   //Para que a exclusao no siga auto seja executada em modo exclusivo e nao esteja locado por outro usuario o pedido de venda ocrrente
	   SC5->(RecLock("SC5"),.F.)	
            
	   _lOK_RDC := .T.

	   If SC5->C5_I_ENVRD = "S"
	      If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms 
             FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS094E(P)} , 'Aguarde!' , 'Enviando para o RDC o cancelamento do Pedido Remessa...') 
		  Else
             FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS140E(P,.T.)} , 'Aguarde!' , 'Enviando para o TMS Multi-Embarcador o cancelamento do Pedido Remessa...') 
		  EndIf 
       Else

			If SC5->C5_I_OPER == '05' .And. !Empty(SC5->C5_I_PVREM) 
				
				_nRecnoSC5 := SC5->(RECNO())
				_nOrderSC5 := SC5->(IndexOrd())	

				SC5->(DBSetOrder(1))
				If SC5->( DBSeek( xFilial("SC5") + SC5->C5_I_PVREM ) )

					If SC5->C5_I_ENVRD = "S"
					   If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms
						  FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS094E(P)} , 'Aguarde!' , 'Enviando para o RDC o cancelamento do Pedido Remessa...') 
					   Else
                          FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS140E(P,.T.)} , 'Aguarde!' , 'Enviando para o TMS Multi-Embarcador o cancelamento do Pedido Remessa...')  
					   EndIf 
					EndIf

					If _lOK_RDC
						_aCabcPVRe := {	{ "C5_FILIAL"  , SC5->C5_FILIAL   			,Nil},;
										{ "C5_NUM"     , SC5->C5_NUM         		,Nil},;
										{ "C5_TIPO"    , SC5->C5_TIPO    			,Nil},;
										{ "C5_CLIENTE" , SC5->C5_CLIENTE 			,Nil},;
										{ "C5_LOJACLI" , SC5->C5_LOJACLI 			,Nil},;
										{ "C5_CLIENT " , SC5->C5_CLIENT  			,Nil},; // Codigo do cliente
										{ "C5_LOJAENT" , SC5->C5_LOJAENT 			,Nil},; // Loja para entrada
										{ "C5_TIPOCLI" , SC5->C5_TIPOCLI 			,Nil},;
										{ "C5_CONDPAG" , SC5->C5_CONDPAG 			,Nil},;
										{ "C5_VEND1"   , SC5->C5_VEND1   			,Nil},;
										{ "C5_EMISSAO" , SToD(SC5->C5_EMISSAO) 		,Nil},;
										{ "C5_TPFRETE" , SC5->C5_TPFRETE 			,Nil},;
										{ "C5_VOLUME1" , SC5->C5_VOLUME1 			,Nil},;
										{ "C5_ESPECI1" , SC5->C5_ESPECI1 			,Nil},;
										{ "C5_TPCARGA" , SC5->C5_TPCARGA 			,Nil},;
										{ "C5_I_AGEND" , SC5->C5_I_AGEND 			,Nil},;
										{ "C5_I_ENVRD" , "N"                		,Nil},;							
										{ "C5_I_IDPED" , SC5->C5_I_IDPED			,Nil} } 

						SC6->( DBSetOrder(1) )
						If SC6->( DBSeek( xFilial("SC6") + SC5->C5_NUM ) )
							While SC5->C5_FILIAL + SC5->C5_NUM == SC6->C6_FILIAL + SC6->C6_NUM .And. SC6->(!Eof())
								
								If !Empty(MV_PAR14)
									If !(AllTrim(SC6->C6_PRODUTO) $ MV_PAR14)
										SC6->(DBSkip())
										Loop
									EndIf
								EndIf

								aAdd( _aItenPVRe , {	{ "C6_FILIAL"  , SC6->C6_FILIAL		,Nil},; 
														{ "C6_ITEM"    , SC6->C6_ITEM		,Nil},;
														{ "C6_PRODUTO" , SC6->C6_PRODUTO	,Nil},;
														{ "C6_QTDVEN"  , SC6->C6_QTDVEN		,Nil},;
														{ "C6_UM"      , SC6->C6_UM			,Nil},;
														{ "C6_PRCVEN"  , SC6->C6_PRCVEN		,Nil},;
														{ "C6_VALOR"   , SC6->C6_VALOR	    ,Nil},;
														{ "C6_PEDCLI"  , SC6->C6_PEDCLI		,Nil},;
														{ "C6_QTDLIB"  , SC6->C6_QTDLIB		,Nil},;
														{ "C6_LOCAL"   , SC6->C6_LOCAL	    ,Nil},;
														{ "C6_NUM"     , SC6->C6_NUM		,Nil}})
								
								SC6->(DBSkip())
							EndDo
						EndIf
					EndIf

					lMsErroAuto := .F.

					//Altera para estornar liberações
					MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVRe , _aItenPVRe , 4 )

					//Exclui pedidos
					MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVRe , _aItenPVRe , 5 )
				EndIf

				SC5->(DBGoTo(_nRecnoSC5))
				SC5->(DBSetOrder(_nOrderSC5))

			EndIf


	   EndIf

       _lExclParcial := .T.
       
	   //INICIO
	   If _lOK_RDC

	   		If _lexclui   //Exclui pedido inteiro

	   			lMsErroAuto := .F.
	   			//Altera para estornar liberações
	   			MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensig , 4 )
	   			
	   			 _cmotivs := _clocmot //volta motivo de corte pois o execauto zera a variável pública
	   			
	   			//Exclui pedidos
	   			MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensig , 5 )
	   			
	   			 _cmotivs := _clocmot //volta motivo de corte pois o execauto zera a variável pública
	   			
	   		Else//Só exclui itens
	   		
	   			lMsErroAuto := .F.
	   			   			
	   			//Exclui itens
	   			MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )
	   			
	   			 _cmotivs := _clocmot //volta motivo de corte pois o execauto zera a variável pública
	   		
	   		EndIf  
		
	   EndIf

	   //FIM 	

	   If lMsErroAuto .Or. !_lOK_RDC
	   	  If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms 	
		     aAdd(_alista2,{SC5->C5_NUM, IIf(_lOK_RDC,"Erro ao alterar Pedido " + SC5->C5_NUM + " no Protheus","Erro ao excluir Pedido " + SC5->C5_NUM + " no RDC!")})
		  Else
             aAdd(_alista2,{SC5->C5_NUM, IIf(_lOK_RDC,"Erro ao alterar Pedido " + SC5->C5_NUM + " no Protheus","Erro ao excluir Pedido " + SC5->C5_NUM + " no TMS Multi-Embarcador!")})
		  EndIf 
	   Else

		  aAdd(_alista2,{SC5->C5_NUM, "Pedido " + SC5->C5_NUM + " cortado com sucesso!"})
		  
	      _cMsg      := "Monitor corte da logistica no pedido de vendas, do(s) produto(s)"  + SubStr(_cprods,1,Len(_cprods)-3) 
	      
          _cCodOper  := "007"
          _dDataOper := Date()
          
          If _lexclui
          
          	_cEncer := "S"
          
          Else
          
          	_cEncer    := "N"
          	
          EndIf
                 
          U_GrvMonitor(SC5->C5_FILIAL,SC5->C5_NUM,_cCodOper,_cMsg,_cEncer,_dDataOper,_dDataOper,_dDataOper) 
          
       EndIf
    
    Else
       
    	_cMsg := "Pedido " + SC5->C5_NUM + " foi faturado ou bloqueado antes do processamento!"
    	lMsErroAuto := .T.
    
    EndIf
    
    _cmotivs := _clocmot //volta motivo de corte pois o execauto zera a variável pública

Return

/*
===============================================================================================================================
Função------------: AOMS109O
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/11/2018
Descrição---------: Tela de opções de armazéns para produtos com bloqueio de estoque
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109O()

Local oBtSair
Local oGrEst
Local oSay1
Local oSayCli
Local oSayCln
Local oSayDt
Local oSayPd
Local oSayPn
Local _cQry			:= ""
Local _nSaldo		:= 0
Local _nY			:= 0
Local _aHeaderIt	:= {}
Local _aColsIt		:= {}
Local _aHeaderEs	:= {}
Local _aColsEs		:= {}
Local _aIn			:= {}
Local _cFilial      := cFilant
Local _cPedido      := TRBF->TRBF_NUM
Local _dDataLib     := TRBF->TRBF_DTLIB 
Local _cCliente     := TRBF->TRBF_CODCL
Local _cLoja        := TRBF->TRBF_LOJCL

Private _nSldTot	:= 0
Private oMSNewGIt
Private oMSNewGEs
Private oDlgEst
_cFilial:= cFilant

aAdd( _aHeaderIt, { 'Status'			, 'CHECKBOL', '@BMP', 10, 0,,, 'C',, 'V' ,  ,  , 'legenda', 'V', 'S' } )
aAdd( _aHeaderIt, {"Item","C9_ITEM   "," ",2,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderIt,{"Produto","C9_PRODUTO","@!                                           ",15,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderIt,{"Qt Liberada","C9_QTDLIB ","@E 9,999,999.999                             ",11,3," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "})
aAdd( _aHeaderIt,{"Prc Venda","C9_PRCVEN ","@E 999,999,999.99999999                      ",18,8," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "})
aAdd( _aHeaderIt,{"Armazem","C9_LOCAL  ","@!                                           ",2,0,'ExistCpo("NNR") ',"€€€€€€€€€€€€€€ ","C","NNR   "," "," "," "})


DBSelectArea("SC9")
SC9->(DBSetOrder(1))
SC9->(DBSeek(_cFilial + _cPedido))

While !SC9->(Eof()) .And. SC9->C9_FILIAL == _cFilial .And. SC9->C9_PEDIDO == _cPedido
	If !Empty(SC9->C9_BLEST) .And. Empty(SC9->C9_BLCRED)
		aAdd(_aColsIt,{LoadBitmap(GetResources(),"BR_PRETO")   , SC9->C9_ITEM, Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"), SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_LOCAL, .F.})
	ElseIf Empty(SC9->C9_BLEST) .And. !Empty(SC9->C9_BLCRED)
		aAdd(_aColsIt,{LoadBitmap(GetResources(),"BR_AZUL")    , SC9->C9_ITEM, Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"), SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_LOCAL, .F.})
	ElseIf !Empty(SC9->C9_BLEST) .And. !Empty(SC9->C9_BLCRED)
		aAdd(_aColsIt,{LoadBitmap(GetResources(),"BR_VERMELHO"), SC9->C9_ITEM, Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"), SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_LOCAL, .F.})
	EndIf
	SC9->(DBSkip())
End

aAdd( _aHeaderEs, { 'Status'			, 'CHECKBOL', '@BMP', 10, 0,,, 'C',, 'V' ,  ,  , 'legenda', 'V', 'S' } )
aAdd( _aHeaderEs, {"Item","C9_ITEM   "," ",2,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderEs,{"Produto","C9_PRODUTO","@!                        ",15,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderEs,{"Codigo","NNR_CODIGO","@!                                           ",2,0,'ExistChav("NNR")      ',"€€€€€€€€€€€€€€°","C"," ","R"," "," "})
aAdd( _aHeaderEs,{"Descricao","NNR_DESCRI","@!                                           ",20,0,"NaoVazio()                ","€€€€€€€€€€€€€€ ","C"," ","R"," "," "})
aAdd( _aHeaderEs,{"Saldo Atual","B2_QATU   ","@E 9,999,999,999.999                         ",14,3," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "})

_cQry := "SELECT C9_ITEM, C9_PRODUTO, C9_LOCAL, NNR_CODIGO, NNR_DESCRI, NNR_I_OPC "
_cQry += "FROM " + RetSqlName("SC9") + " SC9 "
_cQry += "JOIN " + RetSqlName("NNR") + " NNR ON NNR_FILIAL = '" + xFilial("NNR") + "' AND NNR_CODIGO = C9_LOCAL AND NNR.D_E_L_E_T_ = ' ' "
_cQry += "WHERE C9_FILIAL = '" + _cFilial + "' "
_cQry += "  AND C9_PEDIDO = '" + _cPedido + "' "
_cQry += "  AND (C9_BLEST <> ' ' OR C9_BLCRED <> ' ') "
_cQry += "  AND SC9.D_E_L_E_T_ = ' ' "

//dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBARM" , .T., .F. )
MPSysOpenQuery( _cQry , "TRBARM")

DBSelectArea("TRBARM")
TRBARM->(DBGoTop())

If !TRBARM->(Eof())
	While !TRBARM->(Eof())
		_aIn := StrTokArr(TRBARM->C9_LOCAL+";"+AllTrim(TRBARM->NNR_I_OPC),";")
		For _nY := 1 To Len(_aIn)
			DBSelectArea("SB2")
			DBSetOrder(1)
			If DBSeek(xFilial("SB2") + TRBARM->C9_PRODUTO + _aIn[_nY])
				_nSaldo := SaldoSb2()
				If _nSaldo > 0
					_nSldTot += _nSaldo
					aAdd(_aColsEs, {LoadBitmap(GetResources(),"BR_VERDE"),TRBARM->C9_ITEM,Posicione("SB1",1,xFilial("SB1")+TRBARM->C9_PRODUTO,"B1_DESC"),_aIn[_nY],AllTrim(Posicione("NNR",1,xFilial("NNR") + _aIn[_nY],"NNR_DESCRI")),_nSaldo,.F.})
				EndIf
			EndIf
		Next _nY
		TRBARM->(DBSkip())
	End
EndIf

_aColsEs := aSort(_aColsEs,,,{|x,y| x[2] < y[2]})

DBSelectArea("TRBARM")
TRBARM->(DBCloseArea())

DEFINE MSDIALOG oDlgEst TITLE "Ocorreram restrições na liberação do pedido:" FROM 000, 000  To 520, 700 COLORS 0, 16777215 PIXEL

	@ 009, 006 Say oSayPd PROMPT "Pedido:" SIZE 022, 007 OF oDlgEst COLORS 0, 16777215 PIXEL
	@ 009, 030 Say oSayPn PROMPT _cPedido SIZE 025, 007 OF oDlgEst COLORS 16711680, 16777215 PIXEL
	@ 009, 062 Say oSayDt PROMPT "Emissão:" SIZE 025, 007 OF oDlgEst COLORS 0, 16777215 PIXEL
	@ 009, 090 Say oSay1 PROMPT _dDataLib SIZE 032, 007 OF oDlgEst COLORS 16711680, 16777215 PIXEL
	@ 009, 130 Say oSayCli PROMPT "Cliente:" SIZE 019, 007 OF oDlgEst COLORS 0, 16777215 PIXEL
	@ 009, 150 Say oSayCln PROMPT _cCliente + "/" + _cLoja + "-" + Posicione("SA1", 1, xFilial("SA1") + _cCliente + _cLoja, "A1_NOME") SIZE 149, 007 OF oDlgEst COLORS 16711680, 16777215 PIXEL
	@ 005, 305 BUTTON oBtSair PROMPT "Sair" SIZE 037, 012 OF oDlgEst ACTION oDlgEst:End() PIXEL

	oMSNewGIt := MsNewGetDados():New( 025, 006, 127, 343, 0, "AllwaysTrue", "AllwaysTrue", "", {},, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgEst, _aHeaderIt, _aColsIt)

	@ 131, 006 BITMAP oBmp RESNAME "BR_PRETO" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 131, 015 Say "Bloqueio Estoque" OF oDlgEst SIZE 100,10 PIXEL

	@ 131, 106 BITMAP oBmp RESNAME "BR_AZUL" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 131, 115 Say "Bloqueio Crédito" OF oDlgEst SIZE 100,10 PIXEL

	@ 131, 206 BITMAP oBmp RESNAME "BR_VERMELHO" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 131, 215 Say "Bloqueio Estoque/Crédito" OF oDlgEst SIZE 100,10 PIXEL

	@ 141, 006 GROUP oGrEst To 250, 344 PROMPT "Estoques Opcionais" OF oDlgEst COLOR 0, 16777215 PIXEL

	oMSNewGEs := MsNewGetDados():New( 150, 012, 236, 339, 0, "AllwaysTrue", "AllwaysTrue", "", {},, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgEst, _aHeaderEs, _aColsEs)

	@ 240, 009 BITMAP oBmp RESNAME "BR_VERDE" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 240, 018 Say "Com Estoque" OF oDlgEst SIZE 100,10 PIXEL

	@ 240, 150 Say "Saldo Total:" OF oDlgEst SIZE 100,10 PIXEL
	@ 240, 220 Say AllTrim(Transform(_nSldTot,PesqPict("SC9","C9_QTDLIB"))) OF oDlgEst COLORS 0, 16777215 SIZE 100,10 PIXEL

ACTIVATE MSDIALOG oDlgEst CENTERED

Return

/*
===============================================================================================================================
Programa----------: AOMS109CI
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/10/2018
Descrição---------: Seleção de produto para corte de pedidos de vendas
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109CI(oproc)

Local _oDlg2 		:= nil
Local nLinha:=10
Local _nCol:=15
Local _aLstPedV := {}
Local _nI 
Local _nJ

Private _ccomps		:= ""
Private _ccompd		:= ""
Private _Acomps       := {}
Private _ocomps       := nil
Private _Acompd       := {}
Private _ocompd       := nil
Private _lsai         := .T.

//=====================================================================
// Retorna um Array com grupos de produtos selecionados pelo usuário.
//=====================================================================
_aLstPedV := RetSelecPV() 

//=======================================
// Se não tem registros já retorna
//=======================================
If Empty(_aLstPedV) // Empty(_cNumPed)
   U_ITMsg("Nenhum registro válido selecionado","Atenção","Somente registros com bloqueio de estoque (legenda azul) são válidos para corte de produtos",1)
   TRBF->(DBGoTop())
   Return
EndIf


//============================================================
// Faz o estorno de liberação por grupos de pedidos de vendas.
//============================================================	
SC9->(DBSetOrder(1)) // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED

_cNumPed := ""

For _nI := 1 To Len(_aLstPedV)
    _cNumPed += _aLstPedV[_nI,2] +"; "

    SC9->(MsSeek(_aLstPedV[_nI,1]+_aLstPedV[_nI,2]))
	While ! SC9->(Eof()) .And. SC9->C9_FILIAL + SC9->C9_PEDIDO == _aLstPedV[_nI,1] + _aLstPedV[_nI,2]
       If ! Empty(SC9->C9_BLEST)
	      _nJ := aScan(_ACOMPS,{|x| SubStr(x,1,15) == SC9->C9_PRODUTO})
	      If _nJ == 0
             aAdd(_ACOMPS,SC9->C9_PRODUTO + " - " + Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"))
	      EndIf 
	   EndIf 
	   
       SC9->(DBSkip())
	EndDo 
    
Next 

If Len(_ACOMPS) = 0
   U_ITMsg("Nenhum registro encontrado para o(s) pedido(s): " + _cNumPed ,"Atenção",,1)
   Return
EndIf

_cQuery := " SELECT "
_cQuery += " DISTINCT X5_CHAVE CHAVE,X5_DESCRI DESCRI "
_cQuery += " FROM "+ RetSqlName("SX5") +" X5 "
_cQuery += " WHERE "
_cQuery += "     D_E_L_E_T_ = ' ' "
_cQuery += " AND X5_TABELA  = 'Z1' AND TRIM(X5_CHAVE) <> '98' AND TRIM(X5_CHAVE) <> '99' "
_cQuery += " ORDER BY X5_CHAVE "

If Select("TMPCF") > 0 
   ("TMPCF")->( DBCloseArea() )
EndIf

MPSysOpenQuery( _cQuery , 'TMPCF')

DBSelectArea('TMPCF')

_amotivs := {}

While TMPCF->( !Eof() )
   aAdd( _amotivs , AllTrim( TMPCF->CHAVE ) + " - " + AllTrim( TMPCF->DESCRI ) )
   TMPCF->( DBSkip() )
EndDo

("TMPCF")->( DBCloseArea() )

Public _cmotivs := _AMOTIVS[1]

DEFINE MSDIALOG _oDlg2 TITLE ("Corte de produto em PVs") From 0,0 To 325, 650 OF oMainWnd PIXEL
                                                                      
   @ nLinha,_nCol Say OemToAnsi("Selecione o produto para corte:")
   nLinha+=12

   _ocomps := TComboBox():New(nLinha,_nCol,{|u|If(PCount()>0,_ccomps:=u,_ccomps)}, _acomps,250,20,_oDlg2,,;
							{|| AOMS109CH(_acomps[_ocomps:nat],2)},,,,.T.,,,,,,,,,'') //40
							
   nLinha+=38

   @ nLinha,_nCol Say OemToAnsi("Selecione o motivo para corte:")
   nLinha+=12

   TComboBox():New(nLinha,_nCol,{|u|If(PCount()>0,_cmotivs:=u,_cmotivs)}, _amotivs,250,20,_oDlg2,,,,,,.T.,,,,,,,,,'') //40

   nLinha+=38

   AOMS109CH(_acomps[1],2)

   @ nLinha,_nCol    Button "Corta" SIZE 41,15 ACTION ( FWMsgRun(, { |oproc| AOMS109CT(oproc) }, "Aguarde...","Cortando pedidos...") ,TRBF->(DBGoTop()), IIf(_lsai,_oDlg2:End(),_lsai:= .T.)) Pixel 
   @ nLinha,_nCol+57 Button "Cancela"     SIZE 41,15 ACTION ( TRBF->(DBGoTop()),_oDlg2:End() ) Pixel 

ACTIVATE MSDIALOG _oDlg2 

Return 

/*
===============================================================================================================================
Programa----------: AOMS109DR
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/11/2018
Descrição---------: Função que devolve PVs para o RDC
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109DR(oproc)

Local _cTextoMsg := ""
Local _aLstPedV := {}
Local _nI 

//=====================================================================
// Retorna um Array com grupos de produtos selecionados pelo usuário.
//=====================================================================
_aLstPedV := RetSelecPV() 

//====================================================
// Se não tem pedido selecionado já sai da rotina
//====================================================
If Empty(_aLstPedV) // Empty(_cNumPed)
   U_ITMsg("Nenhum pedido selecionado.","Atenção",,1)
   TRBF->(DBGoTop())
   Return
EndIf
	
//================================================================================
// Percorre os pedidos selecionados e monta o cabecalho e itens do pedido de venda
//================================================================================
Begin Transaction
	
   _npv := 0
   _alista := {}
   SC5->(DBSetOrder(1))
   SA1->(DBSetOrder(1))
   SC9->(DBSetOrder(1))
   For _nI := 1 To Len(_aLstPedV)
	   
	   SC5->(DBGoTo(_aLstPedV[_nI,3]))

	   _cNumPed := SC5->C5_NUM         
	   _npv++
		
	   //Atualiza régua
	   oproc:cCaption := ("Processando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	   ProcessMessages()

       //=======================================================================================================
       // Caso outro usuario exclua, fature ou carregue o Pedido de Venda posteriormente ao usuario ter 
       // filtrado os dados
       //========================================================================================================
       If Empty(SC5->C5_NOTA) .And. (!SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .Or. (Empty(SC9->C9_CARGA) .And. Empty(SC9->C9_NFISCAL) ) ) // ( SC5->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. 
          oproc:cCaption := ("Devolvendo para o TMS Multi-Embarcador o PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
			 
  	      ProcessMessages()
            
          //================================================================================
          // Realiza a devolução do pedido de vendas selecionados e 
          // atualiza tabelas de muro.
          //================================================================================
   
          RecLock("SC5",.F.)
          SC5->C5_I_ENVRD := "N"
          SC5->C5_I_DTRET := SToD("") // Data de retorno do pedido de vendas do RDC para o Protheus
          SC5->C5_I_HRRET := ""       // Hora de retorno do pedidod e vendas do RDC para o Protheus
          SC5->(MSUnLock())
   
          FWMsgRun(,{|oproc| U_AOMS084P(,oproc)},'Aguarde processamento...','Integrando dados devolução do PV: '+SC5->C5_NUM+' ['+ StrZero(_npv,6) +'] de ['+ StrZero(nQtdTit,6) +']')
                        

          _cmsglibpv :=  "Devolvido para o TMS" 
			 
			
		  If !Empty(_cmsglibpv)
		     aAdd(_alista,{_cNumPed,_cmsglibpv})
          EndIf
       Else
  		  //Registra problema com pedido
		  If !SC5->( DBSeek( xFilial("SC5") + _cNumPed ) )
		     aAdd(_alista,{_cNumPed, "Pedido foi EXCLUIDO antes do processamento"})
		  ElseIf !Empty(SC5->C5_NOTA) 
		     aAdd(_alista,{_cNumPed, "Pedido foi FATURADO antes do processamento"})
		  ElseIf SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. (!Empty(SC9->C9_CARGA) .Or. !Empty(SC9->C9_NFISCAL) )
             aAdd(_alista,{_cNumPed, "Pedido CARREGADO antes do processamento"})
		  EndIf
	   EndIf
   Next

End Transaction

If Len(_alista) > 0
   _cTextoMsg := "Pedidos devolvidos para o TMS" 
   U_ITListBox( _cTextoMsg , {"Numero","Situacao"} , _alista , .T. , 1 )
EndIf

//Atualiza tela
FWMsgRun( , {|oproc| AOMS109ARQ(oproc) }, "Aguarde!" , 'Carregando dados...' )

Return

/*
===============================================================================================================================
Programa----------: AOMS109BO
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/04/2019
Descrição---------: Aplicação de bloqueio logístico nos pedidos de vendas selecionados
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109BO(oproc)

Local _aLstPedV := {}
Local _nI 

//Verifica permissão de ajuste de bloqueio logístico
ZZL->(DBSetOrder(3))
If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"

   	U_ITMsg("Usuário sem permissão para Definir Pedido em Planejamento Logístico","Atenção",,1)    	    	    
    Return

EndIf

//=====================================================================
// Retorna um Array com grupos de produtos selecionados pelo usuário.
//=====================================================================
_aLstPedV := RetSelecPV() 

//===================================================
// Se não tem pedido selecionado já sai da rotina
//===================================================
If Empty(_aLstPedV) // Empty(_cNumPed)
   U_ITMsg("Nenhum pedido selecionado","Atenção",,1)
   TRBF->(DBGoTop())
   Return
EndIf

Begin Transaction
	
   _npv := 0
   _alista := {}
   SC5->(DBSetOrder(1))
   SA1->(DBSetOrder(1))
   SC9->(DBSetOrder(1))
	   
   For _nI := 1 To Len(_aLstPedV)
	   
       SC5->(DBGoTo(_aLstPedV[_nI,3]))	

	  _cNumPed := SC5->C5_NUM         
	  _npv++
		
	  //Atualiza régua
	  oproc:cCaption := ("Processando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	  ProcessMessages()
		
	  _aAreaCabec := SC5->( FWGetArea() )

	  //=======================================================================================================
	  // Caso outro usuario exclua, fature ou carregue o Pedido de Venda posteriormente ao usuario ter 
	  // filtrado os dados
	  //========================================================================================================
	  If Empty(SC5->C5_NOTA) .And. (!SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .Or. (Empty(SC9->C9_CARGA) .And. Empty(SC9->C9_NFISCAL))) // ( SC5->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. 
	     oproc:cCaption := ("Definindo PV em Planejamento Logístico: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	     ProcessMessages()
            
         U_MOMS042P("S") //Rotina de marcação de bloqueio logístico
			
      	 aAdd(_alista,{_cNumPed,"Bloqueio aplicado com SUCESSO"})
	  Else
		 //Registra problema com pedido
		 If !SC5->( DBSeek( xFilial("SC5") + _cNumPed ) )
			aAdd(_alista,{_cNumPed, "Pedido foi EXCLUIDO antes do processamento"})
		 ElseIf !Empty(SC5->C5_NOTA) 
			aAdd(_alista,{_cNumPed, "Pedido foi FATURADO antes do processamento"})
  		 ElseIf SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. (!Empty(SC9->C9_CARGA) .Or. !Empty(SC9->C9_NFISCAL) )
  			aAdd(_alista,{_cNumPed, "Pedido CARREGADO antes do processamento"})
		 EndIf
	  EndIf
   Next			
End Transaction

If Len(_alista) > 0
	U_ITListBox( "Aplicado Planejamento Logístico nos Pedidos " , {"Numero","Situacao"} , _alista , .T. , 1 )
EndIf
	
SC5->( DBCloseArea() )

//Atualiza tela
FWMsgRun( , {|oproc| AOMS109ARQ(oproc) }, "Aguarde!" , 'Carregando dados...' )

Return

/*
===============================================================================================================================
Programa----------: AOMS109DO
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/04/2019
Descrição---------: Retirada de bloqueio logístico nos pedidos de vendas selecionados
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109DO(oproc)

Local _aLstPedV := {}
Local _nI 

//Verifica permissão de ajuste de bloqueio logístico
ZZL->(DBSetOrder(3))
If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"

 	U_ITMsg("Usuário sem permissão para Definir Pedido em Planejamento Logístico","Atenção",,1)    	    	    
    Return

EndIf

//=====================================================================
// Retorna um Array com grupos de produtos selecionados pelo usuário.
//=====================================================================
_aLstPedV := RetSelecPV() 

//==================================================
// Se não tem pedido selecionado já sai da rotina
//==================================================
If Empty(_aLstPedV) // Empty(_cNumPed)
   U_ITMsg("Nenhum pedido selecionado","Atenção",,1)
   TRBF->(DBGoTop())
   Return
EndIf

Begin Transaction
   _npv := 0
   _alista := {}
   SC5->(DBSetOrder(1))
   SA1->(DBSetOrder(1))
   SC9->(DBSetOrder(1))
   
   For _nI := 1 To Len(_aLstPedV)	

	   SC5->(DBGoTo(_aLstPedV[_nI,3]))   
		  
	   _cNumPed := SC5->C5_NUM         
		 
	   _npv++
	   //Atualiza régua
	   oproc:cCaption := ("Processando PV: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
	   ProcessMessages()
		
	   _aAreaCabec := SC5->( FWGetArea() )

	   //=======================================================================================================
	   // Caso outro usuario exclua, fature ou carregue o Pedido de Venda posteriormente ao usuario ter 
	   // filtrado os dados
	   //========================================================================================================
	   If Empty(SC5->C5_NOTA) .And. (!SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .Or. (Empty(SC9->C9_CARGA) .And. Empty(SC9->C9_NFISCAL) ) )
	      oproc:cCaption := ("Retirando Pedido do Planejamento Logístico: "+SC5->C5_NUM+" ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
		  ProcessMessages()
            
          U_MOMS042P("N") //Rotina de marcação de bloqueio logístico
			
		  aAdd(_alista,{_cNumPed,"Bloqueio retirado com SUCESSO"})
	   Else
		  // Registra problema com pedido
		  If !SC5->( DBSeek( xFilial("SC5") + _cNumPed ) )
		     aAdd(_alista,{_cNumPed, "Pedido foi EXCLUIDO antes do processamento"})
		  ElseIf !Empty(SC5->C5_NOTA) 
			 aAdd(_alista,{_cNumPed, "Pedido foi FATURADO antes do processamento"})
		  ElseIf SC9->(DBSeek(SC5->C5_FILIAL + SC5->C5_NUM)) .And. (!Empty(SC9->C9_CARGA) .Or. !Empty(SC9->C9_NFISCAL) )
  			 aAdd(_alista,{_cNumPed, "Pedido CARREGADO antes do processamento"})
		  EndIf
	   EndIf
		
	   FWRestArea(_aAreaCabec)
   Next

End Transaction

If Len(_alista) > 0
	U_ITListBox( "Pedido Retirado do Planejamento Logístico" , {"Numero","Situacao"} , _alista , .T. , 1 )
EndIf

//Atualiza tela
FWMsgRun( , {|oproc| AOMS109ARQ(oproc) }, "Aguarde!" , 'Carregando dados...' )

Return

/*
===============================================================================================================================
Programa----------: AOMS109DS
Autor-------------: Josué Danich
Data da Criacao---: 11/04/2019
Descrição---------: Função para desmembrar Pedidos de Vendas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109DS()   

DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( TRBF->( TRBF_FILIA + TRBF_NUM ) ) )
	Inclui := .F.
	Altera := .F.
	CCADASTRO := 'Central de PVs - Desmembramento'
	If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms
	   aRotina := {{"Pesquisar","AxPesqui",0,1,0,.F.},;
		    	   {"Visualizar","A410Visual",0,2,0, },;
				   {"Incluir","A410Inclui",0,3,0, },;
				   {"Alterar","A410Altera",0,4,20, },;
				   {"Excluir",{ , },0,5,0, },;
				   {"Cod.barra",{ , },0,3,0, },;
				   {"Copiar","a410PCopia('SC5',SC5->(RecNo()),4)",0,6,0, },;
				   {"reTornar","A410Devol('SC5',SC5->(RecNo()),4)",0,3,0, },;
				   {"prep.Doc.saída","Ma410PvNfs",0,2,0, },;
				   {"Tracker contábil","CTBC662",0,7,0, },;
				   {"Legenda","A410Legend",0,1,0,.F.},;
			 	   {"Relacionadas",{ },0,8,3,.T.},;
				   {"Manutencao","U_AOMS026",0,2,0, },;
				   {"Transferir Pedido","U_AOMS032()",0,2,0, },;
				   {"Imprimir","U_ROMS007",0,2,0, },;
				   {"Espelho ped portal","U_MA410ESP()",0,2,0, },;
				   {"WF Liberacao","U_MOMS030()",0,2,0, },;
				   {"Localiza PV","U_MA410LPV",0,2,0, },;
				   {"Solic.Ret.Pedido <== RDC","U_AOMS084B()",0,2,0, },;
				   {"Devolve Pedido ==> RDC","U_AOMS084F()",0,2,0, },;
				   {"Desmembra Pedido","U_AOMS099()",0,2,0, },;
				   {"Canhoto NF","U_VISCANHO()",0,2,0, },;
				   {"Consulta Historico","U_COMS001()",0,2,0, },;
				   {"Vincula Pedido","U_AOMS110()",0,2,0, },;
				   {"WF Desb Cliente","U_MOMS041Z()",0,2,0, },;
				   {"Planej Logistico","U_MOMS042()",0,2,0, }}
    Else
       aRotina := {{"Pesquisar","AxPesqui",0,1,0,.F.},;
		    	   {"Visualizar","A410Visual",0,2,0, },;
				   {"Incluir","A410Inclui",0,3,0, },;
				   {"Alterar","A410Altera",0,4,20, },;
				   {"Excluir",{ , },0,5,0, },;
				   {"Cod.barra",{ , },0,3,0, },;
				   {"Copiar","a410PCopia('SC5',SC5->(RecNo()),4)",0,6,0, },;
				   {"reTornar","A410Devol('SC5',SC5->(RecNo()),4)",0,3,0, },;
				   {"prep.Doc.saída","Ma410PvNfs",0,2,0, },;
				   {"Tracker contábil","CTBC662",0,7,0, },;
				   {"Legenda","A410Legend",0,1,0,.F.},;
			 	   {"Relacionadas",{ },0,8,3,.T.},;
				   {"Manutencao","U_AOMS026",0,2,0, },;
				   {"Transferir Pedido","U_AOMS032()",0,2,0, },;
				   {"Imprimir","U_ROMS007",0,2,0, },;
				   {"Espelho ped portal","U_MA410ESP()",0,2,0, },;
				   {"WF Liberacao","U_MOMS030()",0,2,0, },;
				   {"Localiza PV","U_MA410LPV",0,2,0, },;
				   {"Solic.Ret.Pedido <== TMS Multi-Embarcador","U_AOMS084B()",0,2,0, },;
				   {"Devolve Pedido ==> TMS Multi-Embarcador","U_AOMS084F()",0,2,0, },;
				   {"Desmembra Pedido","U_AOMS099()",0,2,0, },;
				   {"Canhoto NF","U_VISCANHO()",0,2,0, },;
				   {"Consulta Historico","U_COMS001()",0,2,0, },;
				   {"Vincula Pedido","U_AOMS110()",0,2,0, },;
				   {"WF Desb Cliente","U_MOMS041Z()",0,2,0, },;
				   {"Planej Logistico","U_MOMS042()",0,2,0, }}
	EndIf 

	U_AOMS099()

EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS109AP
Autor-------------: Josué Danich
Data da Criacao---: 11/04/2019
Descrição---------: Função para alterar Pedidos de Vendas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109AP()   
                              
DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( TRBF->( TRBF_FILIA + TRBF_NUM ) ) )
	Inclui := .F.
	Altera := .T.
	MatA410(Nil, Nil, Nil, Nil, "A410Altera") 
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS109HI
Autor-------------: Josué Danich
Data da Criacao---: 12/04/2019
Descrição---------: Função para visualizar histórico do Pedido de Venda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109HI()   
                              
DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( TRBF->( TRBF_FILIA + TRBF_NUM ) ) )
	U_COMS001() 
EndIf

Return


/*
===============================================================================================================================
Programa----------: AOMS109A2
Autor-------------: Josué Danich Prestes
Data da Criacao---: 17/05/2019
Descrição---------: Rotina para criação do arquivo temporário para transferência de pedidos
Parametros--------: Nenhum
Retorno-----------: _lRet - se localizou registros marcados ou não
===============================================================================================================================
*/
Static Function AOMS109A2()

Local aEstru		:= {}
Local _lRet         := .T.
Private linverte    := .F.

//================================================================================
// Armazena no array aEstru a estrutura dos campos da tabela.
//================================================================================
aAdd( aEstru , { "TRBT_OK"		, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBT_FILIA"	, 'C' , 02 , 0 } )    
aAdd( aEstru , { "TRBT_NUM"		, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBT_DTEMI"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBT_CODCL"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBT_LOJCL"	, 'C' , 04 , 0 } )
aAdd( aEstru , { "TRBT_DESCL"	, 'C' , 30 , 0 } )
aAdd( aEstru , { "TRBT_CODRE"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBT_DESCR"	, 'C' , 20 , 0 } )
aAdd( aEstru , { "TRBT_CODVE"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBT_DESVE"	, 'C' , 25 , 0 } )
aAdd( aEstru , { "TRBT_VALOR"	, 'N' , 14 , 2 } )
aAdd( aEstru , { "TRBT_FILCR"	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBT_FILFT"	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBT_AGEND"	, 'C' , 01 , 0 } )
aAdd( aEstru , { "C5_I_PEVIN"	, 'C' , Len(SC5->C5_I_PEVIN),0})
aAdd( aEstru , { "C5_I_ENVRD"	, 'C' , Len(SC5->C5_I_ENVRD),0})
aAdd( aEstru , { "C5_I_PVREM"	, 'C' , 06 , 0 } )  // PV Remessa - Operação Triangular


//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("TRBT") > 0
	TRBT->( DBCloseArea() )
EndIf

//================================================================================
// Permite o uso do arquivo criado dentro do protheus.
//================================================================================
_otemp := FWTemporaryTable():New( "TRBT", aEstru )

_otemp:AddIndex( "01", {"TRBT_NUM"} )
_otemp:AddIndex( "02", {"TRBT_CODCL","TRBT_LOJCL"} )
_otemp:AddIndex( "03", {"TRBT_DESCL"} )
_otemp:AddIndex( "04", {"TRBT_DESCR"} )
_otemp:AddIndex( "05", {"C5_I_PVREM"} )

_otemp:Create()

TRBF->(DBGoTop())

While TRBF->(!Eof())
	
	//================================================================================
	// Somente pedidos selecionados pelo usuario
	//================================================================================
	If (TRBF->TRBF_OK == cMarkado) 

		//Posiciona tabelas
		SC5->(DBSetOrder())
		If !(SC5->(DBSeek(TRBF->TRBF_FILIA+TRBF->TRBF_NUM)))   //Se não achar na sc5 pula para próximo marcado
			TRBF->( DBSkip() )
			Loop
		EndIf

		_lRet := .T.

		//Registra na TRBT para a rotina de transferência	 	
		TRBT->(DBAPPEND())
		TRBT->TRBT_FILIA	:= SC5->C5_FILIAL
		TRBT->TRBT_NUM		:= SC5->C5_NUM
		TRBT->TRBT_DTEMI	:= SC5->C5_EMISSAO
		TRBT->TRBT_CODCL	:= SC5->C5_CLIENTE
		TRBT->TRBT_LOJCL	:= SC5->C5_LOJACLI
		TRBT->TRBT_DESCL	:= Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")
		TRBT->TRBT_CODRE	:= SC5->C5_I_GRPVE
		TRBT->TRBT_DESCR	:= SC5->C5_I_NOMRD
		TRBT->TRBT_CODVE	:= SC5->C5_VEND1
		TRBT->TRBT_DESVE	:= Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NOME")
		TRBT->TRBT_FILCR    := SC5->C5_I_FLFNC//Filial de Carregamento
		TRBT->TRBT_FILFT 	:= SC5->C5_I_FILFT//Filial de Faturamento
		TRBT->TRBT_AGEND 	:= SC5->C5_I_AGEND 
		TRBT->C5_I_PEVIN 	:= SC5->C5_I_PEVIN//PV Vinculado
		TRBT->C5_I_ENVRD 	:= SC5->C5_I_ENVRD//PV RDC
		TRBT->TRBT_OK       := cMarkado
		TRBT->C5_I_PVREM    := SC5->C5_I_PVREM // PV Remessa
	EndIf
		
  	TRBF->( DBSkip() )

EndDo

Return _lRet 

/*
===============================================================================================================================
Programa----------: AOMS109G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/11/2019
Descrição---------: Rotina de Alterações de armazéns.
Parametros--------: oproc = Objeto de processamento para imcrementação da régua de processamento.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS109G(oproc)

Local _aPedLocal := {}      
Local _aPedSC9   := {}
Local _nI, _nJ
Local _aButtons := {}
Local _aNoFields 
Local _cCampo     
Local _aHdBack := {}
Local _aObjects := {}
Local _aPosObj  := {}
Local _aSize    
Local _aInfo    
Local _nRegAtu := TRBF->(Recno())       
Local _nRegSC5 := SC5->(Recno())

Private l410AUTO := .F.
Private aRotina := {{"Pesquisar" ,"AxPesqui"  ,0,1,0,.F.},;
				    {"Visualizar","A410Visual",0,2,0, },;
				    {"Incluir"   ,"AxInclui"  ,0,3,0, },;
				    {"Alterar"   ,"AxAltera"  ,0,4,20, },;
			 	    {"Excluir"   ,"AxExclui"  ,0,5,0, }}

Private aHeader, _aHeaderBack , aCols, _aColsBack, _aHeaderOrig , _aColsOrig
Private _aPedRejeicao := {} 

Begin Sequence 
   N := 1 
   SC9->(DBSetOrder(1)) // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED   
   SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM 
   
   TRBF->(DBGoTop())

   While TRBF->(!Eof())
	  //================================================================================
	  // Somente pedidos selecionados pelo usuario
	  //================================================================================
	  If !Empty(TRBF->TRBF_OK) 
		 //Posiciona tabelas
		 If !(SC5->(DBSeek(TRBF->TRBF_FILIA+TRBF->TRBF_NUM)))   //Se não achar na sc5 pula para próximo marcado
            TRBF->(DBSkip())
            Loop
         EndIf
          
         If SC9->(DBSeek(TRBF->TRBF_FILIA+TRBF->TRBF_NUM))             
            aAdd(_aPedSC9,{TRBF->TRBF_FILIA,TRBF->TRBF_NUM, "Pedido de Vendas já liberado. Não é permitido alterar o armazem."})
                    
            TRBF->(DBSkip())
            Loop
         EndIf
             
         aAdd(_aPedLocal, {TRBF->TRBF_FILIA, TRBF->TRBF_NUM})
      EndIf
       
      TRBF->(DBSkip())
   EndDo    
    
   If ! Empty(_aPedSC9)
      U_ITListBox( "Pedidos de Vendas com Liberação" , {"Filial","Pedido de Vendas","Observação"} , _aPedSC9 , .T. , 1 )       
   EndIf                                           

   If Empty(_aPedLocal)
      U_ITMsg("Nenhum pedido de vendas foi selecionado.","Atenção",,1)
      Break
   EndIf          
   
   //==================================================================
   // Campos que não serão exibidos na msgetdados.
   //==================================================================           
   _aNoFields := {"C6_SLDALIB",;
                  "C6_INFAD",;
                  "C6_I_QESP",; 
                  "C6_GRADE",;  
                  "C6_TPOP",;   
                  "C6_TPCONTR",;
                  "C6_REGWMS",; 
                  "C6_TPDEDUZ",;
                  "C6_MOTDED",; 
                  "C6_I_DIFPE",;
                  "C6_VDMOST",; 
                  "C6_RATEIO",; 
                  "C6_INTROT",;
                  "C6_TPPROD"} 

   //============================================================================
   //Indica as rotinas abaixo que se trata de alteracao                         
   //=============================================================================
   ALTERA := .T.

   //============================================================================
   // Inicializa desta forma para criar uma nova instancia de variaveis Private 
   //=============================================================================
   RegToMemory( "SC5", .F., .F. )

   //============================================================================
   //Montagem do aheader                                                        
   //============================================================================= 
// FillGetDados(<nOpc>,<cAlias>,[nOrder],[cSeekKey],[ bSeekWhile],[ uSeekFor],[aNoFields],[aYesFields],[ lOnlyYes], [ cQuery], [ bMontCols], [ lEmpty], [ aHeaderAux], [ aColsAux], [ bAfterCols], [ bBeforeCols], [ bAfterHeader], [ cAliasQry], [ bCriaVar], [ lUserFields], [ aYesUsado] )
   FillGetDados(1     ,"SC6"   ,1       ,          ,             ,{||.T.}    ,_aNoFields ,,,,,.T.)

   //============================================================================
   // Incluindo a filial e o numero do pedido de vendas no array aHeader.
   //=============================================================================
   //                     1            2         3           4          5        6        7       8       9       10     
   // aAdd(aHeader,{trim(x3_titulo),x3_campo,x3_picture,x3_tamanho,x3_decimal,x3_valid,x3_usado,x3_tipo, x3_f3,x3_context})
    aAdd( _aHdBack , {  Getsx3cache("C6_FILIAL","X3_TITULO")  ,;  // 1
			            Getsx3cache("C6_FILIAL","X3_CAMPO")   ,;  // 2
			            Getsx3cache("C6_FILIAL","X3_PICTURE") ,;  // 3
			            Getsx3cache("C6_FILIAL","X3_TAMANHO") ,;  // 4
			            Getsx3cache("C6_FILIAL","X3_DECIMAL") ,;  // 5
			            Getsx3cache("C6_FILIAL","X3_VALID")   ,;  // 6
			            Getsx3cache("C6_FILIAL","X3_USADO")   ,;  // 7
			            Getsx3cache("C6_FILIAL","X3_TIPO")    ,;  // 8
			            Getsx3cache("C6_FILIAL","X3_F3")      ,;  // 9
			            Getsx3cache("C6_FILIAL","X3_CONTEXT")  }) // 10
   
   	aAdd( _aHdBack , {  Getsx3cache("C6_NUM","X3_TITULO")  ,;  // 1
			            Getsx3cache("C6_NUM","X3_CAMPO")   ,;  // 2
			            Getsx3cache("C6_NUM","X3_PICTURE") ,;  // 3
			            Getsx3cache("C6_NUM","X3_TAMANHO") ,;  // 4
			            Getsx3cache("C6_NUM","X3_DECIMAL") ,;  // 5
			            Getsx3cache("C6_NUM","X3_VALID")   ,;  // 6
			            Getsx3cache("C6_NUM","X3_USADO")   ,;  // 7
			            Getsx3cache("C6_NUM","X3_TIPO")    ,;  // 8
			            Getsx3cache("C6_NUM","X3_F3")      ,;  // 9
			            Getsx3cache("C6_NUM","X3_CONTEXT")  }) // 10
			            
   For _nI := 1 To Len(aHeader)
       aAdd(_aHdBack, aHeader[_nI])
   Next                            
   
   aHeader := aClone(_aHdBack)
   
   //============================================================================
   // Montagem do aCols                                                          
   //============================================================================
   aCols := {}
   
   For _nI := 1 To Len(_aPedLocal)
	 	   
	   SC6->(DBSeek(_aPedLocal[_nI,1]+_aPedLocal[_nI,2]))
	   
	   While ! SC6->(Eof()) .And. SC6->C6_FILIAL == _aPedLocal[_nI,1] .And. SC6->C6_NUM == _aPedLocal[_nI,2] 
		  //============================================================================
		  // Adiciona os campos no Acols.                                              
		  //=============================================================================
		  aAdd(aCols,Array(Len(aHeader)+1))
		  For _nJ := 1 To Len(aHeader)
			  _cCampo := AllTrim(aHeader[_nJ,2])
			  If ( aHeader[_nJ,10] # "V" .And. ! (_cCampo $ "C6_QTDLIB/C6_ALI_WT/C6_REC_WT")) 
			     aCols[Len(aCols)][_nJ] := &("SC6->"+_cCampo) // FieldGet(FieldPos(cCampo))
			  Else
			     If _cCampo == "C6_ALI_WT"
			        aCols[Len(aCols)][_nJ] := "SC6"
			     ElseIf _cCampo == "C6_REC_WT"
			        aCols[Len(aCols)][_nJ] := SC6->(RecNo()) 
			     Else
				    aCols[Len(aCols)][_nJ] := CriaVar(_cCampo)
			     EndIf
			  EndIf
		  Next _nJ
		  
		  aCols[Len(aCols)][Len(aHeader)+1] := .F.
		
	      SC6->(DBSkip())
	   EndDo
   Next

   lContinua:=.F.
   nOpcA:= 0
   aTela:={}
   aGets:={}
                                 
   aAdd(_aButtons, {"Alt.Todos Armazens" , {|| U_AOMS109N() } , "Altera Todos Armazens dos Pedidos Selecionados"})
   
   //============================================================================
   // Faz um backup do Acols e aHeader antes das alterações
   //============================================================================
   _aHeaderBack := aClone(aHeader)
   _aColsBack   := aClone(aCols)
   _aHeaderOrig := aClone(aHeader)  
   _aColsOrig   := aClone(aCols)
   
   //============================================================================
   // Calculo das dimensoes da Janela                                            
   //============================================================================
   _aSize := MsAdvSize()
   _aInfo := {_aSize[1],_aSize[2],_aSize[3],_aSize[4],3,3}

   aAdd(_aObjects,{100,050,.T.,.F.,.F.})
   aAdd(_aObjects,{100,100,.T.,.T.,.F.})

   _aPosObj:=MsObjSize(_aInfo,_aObjects)
		                                 
   _cCadastro := "Rotina de Alteração de Armazens"	      
	
   DEFINE MSDIALOG oDlg TITLE _cCadastro From _aSize[7],0 To _aSize[6],_aSize[5] of oMainWnd PIXEL
      
      oGetd := MsGetDados():New(30,_aPosObj[2,2],_aPosObj[2,3],_aPosObj[2,4], 4   ,             ,           ,""        , .T. ,{"C6_LOCAL"},    ,    , 100 , 'U_AOMS109J',             , ,          , oDlg) //  ,,,,)  // .F.)  
	   
   ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{||nOpca:=1,If(oGetd:TudoOk(),oDlg:End(),nOpca := 0)},{||oDlg:End()},,_aButtons)  
                                          
   If nOpca == 0
      U_ITMsg("Rotina cancelada pelo usuário.","Atenção",,2)
      Break
   EndIf 
   
   //======================================================================
   // Verifica se houve alterações e grava as alterações na base de dados.
   //======================================================================
   U_AOMS109Q(oproc) 
                      
   //======================================================================
   // Pedidos de Vendas que tiveram a alteração de armazem rejeitada.
   //======================================================================                   
   If ! Empty(_aPedRejeicao)
      U_ITListBox( "Pedidos de Vendas com Alteração de Armazem Rejeitada" , {"Filial","Pedido de Vendas","Observação"} , _aPedRejeicao , .T. , 1 )       
   EndIf
  
End Sequence

TRBF->(DBGoTo(_nRegAtu))
SC5->(DBGoTo(_nRegSC5))

Return  

/*
===============================================================================================================================
Programa----------: AOMS109N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/11/2019
Descrição---------: Permite alterar todos os armazens exibidos na tela de alterações de armazens.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS109N()

Local _oSayLoc, _oGetLoc, _cGetLoc := Space(2) 
Local _nOpca := 0
Local _oDlgA
Local _nI, _nN_Back := N    
Local _nPosFilial := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_FILIAL" } )
Local _nPosPedido := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_NUM"	} )
Local _nPosLocal  := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_LOCAL"	} )
Local _nPosProd   := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRODUTO"} )
Local _nPosTES    := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_TES"} ) 
Local _nPosCF     := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_CF"} ) 
Local _nLocalAtu, _cCodFilial, _cPedido, _cProduto          
Local _cOrdSC5 := SaveOrd({"SC5"}) 
Local _aNaoAlterados := {}
Local _nJ

Begin Sequence

   Define MsDialog _oDlgA Title "Altera Todos os Armazens dos Pedidos de Vendas Selecionados" From 000, 000  To 170, 475 Pixel COLORS 0, 16777215 

	  @ 005, 006 Say _oSayLoc	PROMPT "Novo Armazem:"	Size 046, 007 Of _oDlgA Pixel     //  COLORS 16711680, 16777215
	  @ 017, 006 MsGet _oGetLoc Var _cGetLoc Size 050, 010 Of _oDlgA Valid (ExistCpo("NNR",_cGetLoc))  F3 "NNR" Pixel  // COLORS 0, 16777215

	  Define SBUTTON _oSButtonOk From 065, 085 Type 01 Of _oDlgA Enable Action (_nOpca := 1, _oDlgA:End())
 	  Define SBUTTON _oSButtonCn From 065, 118 Type 02 Of _oDlgA Enable Action _oDlgA:End()

   Activate MsDialog _oDlgA Centered   
   
   If _nOpca ==  0
      U_ITMsg("Rotina cancelada pelo usuário.","Atenção",,2)
      Break
   EndIf
           
   If Empty(_cGetLoc)
      U_ITMsg("Novo armazem não preenchido. Rotina de alteração de armazens para multiplos pedidos de vendas cancelada.","Atenção",,1)
      Break
   EndIf
   
   SC5->(DBSetOrder(1))
                             
   If Len(aCols) > 0
      _cCodFilial := aCols[1, _nPosFilial]
      _cPedido    := aCols[1, _nPosPedido]
      
      SC5->(DBSeek(_cCodFilial+ _cPedido))   
      RegToMemory( "SC5", .F., .F. )
   EndIf
       
   For _nI := 1 To Len(aCols)
       N := _nI
       _nLocalAtu  := aCols[N, _nPosLocal]
       _cProduto   := aCols[N, _nPosProd]
                                            
       If _cCodFilial <> aCols[N, _nPosFilial] .Or. _cPedido <> aCols[N, _nPosPedido] 
          _cCodFilial := aCols[N, _nPosFilial]
          _cPedido    := aCols[N, _nPosPedido] 
          
          SC5->(DBSeek(_cCodFilial+ _cPedido))   
          RegToMemory( "SC5", .F., .F. )
       EndIf
       
       aCols[N, _nPosLocal] := _cGetLoc   
       M->C6_LOCAL := _cGetLoc 
       __ReadVar   := 'M->C6_LOCAL'
       
       If ! A410Local()
          aAdd(_aNaoAlterados, {_cCodFilial,_cPedido,_cProduto,Posicione("SB1",1,xFilial("SB1")+_cProduto,"B1_DESC"),_nLocalAtu,"Não pode ser alterado para o armazem: "+_cGetLoc})
          aCols[N, _nPosLocal] := _nLocalAtu
       Else
          If ExistTrigger('C6_LOCAL  ')  
             RunTrigger(2,n,nil,,'C6_LOCAL  ')  
          EndIf
       EndIf
   Next
   
   If Len(_aNaoAlterados)
      U_ITListBox( "Iten de Pedidos de Vendas que não puderam ser alterados." , {"Filial","Pedido de Vendas","Produto","Descrição","Armazem", "Observação"} , _aNaoAlterados , .T. , 1 )        
   EndIf
   
   For _nI := 1 To Len(aCols)       
       //=============================================================================================
       // Pesquisa no array _aNaoAlterados os itens que não puderam ter o armazem alterado e que não 
       // podem ser atualizados no aCols principal.
       //=============================================================================================
       _nJ := aScan(_aNaoAlterados, {|x| x[1] == aCols[_nI, _nPosFilial] .And. x[2] == aCols[_nI, _nPosPedido] .And. x[3] == aCols[_nI, _nPosProd] })     
       
       If _nJ > 0
          Loop
       EndIf
       
       //===================================================================
       // Atualiza o aCols principal com os armazens que foram alterados.
       //===================================================================
       _nJ := aScan(_aColsBack, {|x| x[_nPosFilial] == aCols[_nI, _nPosFilial] .And. x[_nPosPedido] == aCols[_nI, _nPosPedido] .And. x[_nPosProd] == aCols[_nI, _nPosProd] })            
       
       If _nJ > 0 .And. _aColsBack[_nJ,_nPosLocal] <> aCols[_nI, _nPosLocal] 
          _aColsBack[_nJ,_nPosLocal] := aCols[_nI, _nPosLocal] 
          _aColsBack[_nJ,_nPosTES]   := aCols[_nI, _nPosTES] 
          _aColsBack[_nJ,_nPosCF]    := aCols[_nI, _nPosCF]  
       EndIf    
       
   Next
     
End Sequence

RestOrd(_cOrdSC5)

N := _nN_Back    

aHeader := aClone(_aHeaderBack)
aCols   := aClone(_aColsBack)


Return

/*
===============================================================================================================================
Programa----------: AOMS109Q
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/12/2019
Descrição---------: Grava / Atualiza os pedidos de vendas com os armazens alterados.
Parametros--------: oproc = objeto de tela para régua de processo.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS109Q(oproc)

Local _nI, _nJ
Local _nPosFilial := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_FILIAL" } )
Local _nPosPedido := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_NUM"	} )
Local _nPosLocal  := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_LOCAL"	} )
Local _nPosProd   := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRODUTO"} )  
Local _nPosItem   := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_ITEM"    } )  
Local _nTotLinhas := Len(aCols)
Local _cNrPedido, _cNrFilial

Private _aPedidos, _cChavePed, _lAlterou

Begin Sequence             
   _aPedidos  := {}
   _cChavePed := ""
   _lAlterou  := .F.
   
   _cNrFilial := ""    
   _cNrPedido := "" 
   
   For _nI := 1 To Len(_aColsBack)
       oproc:cCaption := ("Gravando Pedidos de Vendas Alterados: " + _aColsBack[_nI,_nPosPedido] + " ["+ StrZero(_nI,6) +"] de ["+ StrZero(_nTotLinhas,6) +"]")
       ProcessMessages()    
	   
	   //=====================================================================================================
       // Grava o Array _aPedidos com todos os itens de um pedidos de vendas para atualização da base de dados
       //=====================================================================================================                          
                    //        1                          2                           3                           4                     5
	   aAdd(_aPedidos, {_aColsBack[_nI,_nPosFilial],_aColsBack[_nI,_nPosPedido],_aColsBack[_nI,_nPosItem], _aColsBack[_nI,_nPosProd] ,_nI})   
	   If Empty(_cChavePed)
	      _cChavePed := _aColsBack[_nI,_nPosFilial] + _aColsBack[_nI,_nPosPedido]
	      _cNrFilial := _aColsBack[_nI,_nPosFilial]    
          _cNrPedido := _aColsBack[_nI,_nPosPedido]
	   EndIf                                                                                           
	   
	   //====================================================================================================
       // Verifica se houve alguma alteração de Armazem.
       //====================================================================================================   
       _nJ := aScan(_aColsOrig, {|x| x[_nPosFilial] == _aColsBack[_nI, _nPosFilial] .And. x[_nPosPedido] == _aColsBack[_nI, _nPosPedido] .And. x[_nPosProd] == _aColsBack[_nI, _nPosProd] })            
       
       If _nJ > 0 .And. _aColsOrig[_nJ,_nPosLocal] <> _aColsBack[_nI, _nPosLocal] 
          _lAlterou  := .T. 
       EndIf  	                                                                 
       
       If _cChavePed <> _aColsBack[_nI,_nPosFilial] + _aColsBack[_nI,_nPosPedido]
          //=========================================================
          // Grava a alteração de Pedidos utilizando o MSEXECATUTO.
          //=========================================================
		  AOMS109QGR(_cNrFilial,_cNrPedido)      
		  _lAlterou  := .F. 
		  _cChavePed := _aColsBack[_nI,_nPosFilial] + _aColsBack[_nI,_nPosPedido]
		  _cNrFilial := _aColsBack[_nI,_nPosFilial]    
          _cNrPedido := _aColsBack[_nI,_nPosPedido]
       EndIf                     
   Next                                                                          
   
   //=============================================================
   // Grava a alteração do ultimo Pedido de Vendas, caso
   // não tenha sido gravado ainda, utilizando o MSEXECATUTO.
   //=============================================================
   If _lAlterou
      AOMS109QGR(_cNrFilial,_cNrPedido)      
   EndIf   
   
End Sequence

Return

/*
===============================================================================================================================
Programa----------: AOMS109QGR() 
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/12/2019
Descrição---------: Grava / Atualiza os pedidos de vendas com os armazens alterados utilizando MSExecAuto.
Parametros--------: _cNrFilial == Filial do pedido de vendas.
                    _cNrPedido == Numero do pedido dew vendas.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS109QGR(_cNrFilial,_cNrPedido) 

Local _aCabPV  
Local _aItemPV 
Local _aItensPV
Local _nI
Local _nPosFilial := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_FILIAL"  } )
Local _nPosPedido := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_NUM"	  } )
Local _nPosLocal  := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_LOCAL"	  } )
Local _nPosProd   := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRODUTO" } )  
Local _nPosItem   := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_ITEM"    } )  
Local _nPosACols  

Private _cAOMS074Vld := "" 

Begin Sequence
   _aCabPV  :={}
   _aItemPV :={}
   _aItensPV:={}
   
   //===============================================================
   // O Array _Pedidos possui apenas um pedido de vendas por filial.
   // Posiciona Pedidos de Vendas para as alterações do armazem.
   //===============================================================
   SC5->(DBSetOrder(1))   
   SC5->(DBSeek( _cNrFilial + _cNrPedido )) // _aPedidos[1,1]+_aPedidos[1,2]))

   //====================================================================================================
   // Monta o cabeçalho do pedido                                                                        
   //====================================================================================================
   aAdd( _aCabPV, { "C5_FILIAL"  	,SC5->C5_FILIAL  , Nil}) // filial
   aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM	 , Nil}) // Numero do Pedido de Vendas
   aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil}) // Tipo de pedido
   aAdd( _aCabPV, { "C5_I_OPER" 	,SC5->C5_I_OPER  , Nil}) // Tipo da operacao
   aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL}) // Codigo do cliente
   aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT	 , Nil}) // Cliente de Entregra
   aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL}) // Loja Cliente de Entrega
   aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL}) // Loja do cliente
   aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL}) // Data de emissao
   aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP	 , Nil}) // Transpordadora
   aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL}) // Codigo da condicao de pagamanto*
   aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1	 , Nil}) // Vendedor 
   aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil}) // Moeda
   aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD	 , Nil}) // Mensagem padrão para a nota
   aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL}) // Liberacao Total
   aAdd( _aCabPV, { "C5_TIPLIB"  	,SC5->C5_TIPLIB  , Nil}) // Tipo de Liberacao
   aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL}) // Tipo do Cliente
   aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL}) // Numero que originou a pedido de palete
   aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL}) // Pedido Refere a um pedido de Pallet
   aAdd( _aCabPV, { "C5_I_DTENT"	,SC5->C5_I_DTENT , Nil}) // Dt de Entrega foi alterado para data do dia
   aAdd( _aCabPV, { "C5_I_TRCNF"    ,SC5->C5_I_TRCNF , Nil}) // Troca Nota
   aAdd( _aCabPV, { "C5_I_BLPRC"    ,SC5->C5_I_BLPRC , Nil}) // Bloqueio de Preços
   aAdd( _aCabPV, { "C5_I_FILFT"    ,SC5->C5_I_FILFT , Nil}) // Filial de Faturamento
   aAdd( _aCabPV, { "C5_I_FLFNC"    ,SC5->C5_I_FLFNC , Nil})

   //====================================================================================================
   // Monta o item do pedido                                                                             
   //====================================================================================================
   SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

   While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
	  //====================================================================================================
      // Verifica se houve alguma alteração de Armazem.
      //====================================================================================================   
      _nI := aScan(_aPedidos, {|x| x[_nPosFilial] == SC6->C6_FILIAL .And. x[_nPosPedido] == SC5->C5_NUM .And. x[_nPosItem] == SC6->C6_ITEM .And. x[_nPosProd] == SC6->C6_PRODUTO})            

	  If _nI > 0
	     _nPosACols := _aPedidos[_nI, 5]  // Retorna a posição do item no array _aColsBack.
	     
	     _aItemPV:={}

	     aAdd( _aItemPV , { "LINPOS"     ,"C6_ITEM"                           , SC6->C6_ITEM }) //  Informa a posição do item
         aAdd( _aItemPV , { "AUTDELETA"  ,"N"                                 , Nil }) // Informa se o item será ou não excluído.
	     aAdd( _aItemPV , { "C6_FILIAL"  , SC6->C6_FILIAL                     , Nil }) // Filial
	     aAdd( _aItemPV , { "C6_NUM"     , SC6->C6_NUM	                      , Nil }) // Numero do Pedido de Vendas
	     aAdd( _aItemPV , { "C6_PRODUTO" , SC6->C6_PRODUTO                    , Nil }) // Codigo do Produto
	     aAdd( _aItemPV , { "C6_QTDVEN"  , SC6->C6_QTDVEN                     , Nil }) // Quantidade Vendida
	     aAdd( _aItemPV , { "C6_PRCVEN"  , SC6->C6_PRCVEN                     , Nil }) // Preco Unitario Liquido
	     aAdd( _aItemPV , { "C6_PRUNIT"  , SC6->C6_PRUNIT                     , Nil }) // Preco Unitario Liquido
	     aAdd( _aItemPV , { "C6_ENTREG"  , SC6->C6_ENTREG                     , Nil }) // Data da Entrega
	     aAdd( _aItemPV , { "C6_LOJA"    , SC6->C6_LOJA	                      , Nil }) // Loja do Cliente
	     aAdd( _aItemPV , { "C6_SUGENTR" , SC6->C6_SUGENTR                    , Nil }) // Data da Entrega
	     aAdd( _aItemPV , { "C6_VALOR"   , SC6->C6_VALOR                      , Nil }) // valor total do item
	     aAdd( _aItemPV , { "C6_UM"      , SC6->C6_UM                         , Nil }) // Unidade de Medida Primar.
	     aAdd( _aItemPV , { "C6_LOCAL"   , _aColsBack[_nPosACols, _nPosLocal] , Nil }) // Armazem / lmoxarifado  // SC6->C6_LOCAL
	     aAdd( _aItemPV , { "C6_DESCRI"  , SC6->C6_DESCRI                     , Nil }) // Descricao
	     aAdd( _aItemPV , { "C6_QTDLIB"  , SC6->C6_QTDLIB                     , Nil }) // Quantidade Liberada
	     aAdd( _aItemPV , { "C6_PEDCLI"  , SC6->C6_PEDCLI                     , Nil }) // Pedido do Cliente
	     aAdd( _aItemPV , { "C6_I_BLPRC" , SC6->C6_I_BLPRC                    , Nil }) // Bloqueio de Preço
	
	     aAdd( _aItensPV ,_aItemPV )
	  EndIf
	
	  SC6->( DBSkip() )
   EndDo

   //====================================================================================================
   // Grava na base de dados as alterações dos armazens dos pedidos de vendas.
   //====================================================================================================
   lMsErroAuto := .F.
   lAutoErrNoFile := .F.

   MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )

   If lMsErroAuto 
	  //MostraErro()  
	  //aAdd(_aPedRejeicao, {SC5->C5_FILIAL,SC5->C5_NUM,"Alteração de Armazem Rejeitada: " + " [" + MostraErro() + "] "})
	  aAdd(_aPedRejeicao, {SC5->C5_FILIAL,SC5->C5_NUM,"Alteração de Armazem Rejeitada: " + " [" + _cAOMS074Vld + "] "})
   EndIf

End Sequence
                          
Return  

/*
===============================================================================================================================
Programa----------: AOMS109J() 
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/12/2019
Descrição---------: Valida a alteração manual do armazem na linha do aCols.
Parametros--------: Nenhum
Retorno-----------: _lRet == .T. / .F.
===============================================================================================================================
*/                                   
User Function AOMS109J()         

Local _lRet := .T.
Local _cCodFilial, _cPedido
Local _nPosFilial := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_FILIAL"  } )
Local _nPosPedido := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_NUM"	  } )
Local _nPosLocal  := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_LOCAL"	  } )
Local _nPosProd   := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRODUTO" } )     
Local _nPosTES    := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_TES"     } ) 
Local _nPosCF     := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_CF"      } ) 

Begin Sequence
   SC5->(DBSetOrder(1))
                             
   _cCodFilial := aCols[N, _nPosFilial]
   _cPedido    := aCols[N, _nPosPedido]
      
   SC5->(DBSeek(_cCodFilial + _cPedido))   
   RegToMemory( "SC5", .F., .F. )
          
   _nLocalAtu  := aCols[N, _nPosLocal]
   _cProduto   := aCols[N, _nPosProd]
          
   If ExistTrigger('C6_LOCAL  ')  
      RunTrigger(2,n,nil,,'C6_LOCAL  ')  
   EndIf

   //===================================================================
   // Atualiza o aCols principal com os armazens que foram alterados.
   //===================================================================
   _nJ := aScan(_aColsBack, {|x| x[_nPosFilial] == aCols[N, _nPosFilial] .And. x[_nPosPedido] == aCols[N, _nPosPedido] .And. x[_nPosProd] == aCols[N, _nPosProd] })            
       
   If _nJ > 0 .And. _aColsBack[_nJ,_nPosLocal] <> M->C6_LOCAL 
      _aColsBack[_nJ,_nPosLocal] := M->C6_LOCAL 
      _aColsBack[_nJ,_nPosTES]   := aCols[N, _nPosTES] 
      _aColsBack[_nJ,_nPosCF]    := aCols[N, _nPosCF]  
   EndIf    

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS109U()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 23/12/2019
Descrição-------: Verifica e permite o filtro de dados pelo tipo de carga.
Parametros------: _cFilial = Filial do Pedido de Vendas
                  _cPedido = Numero do Pedido de Vendas
Retorno---------: .T. / .F. 
===============================================================================================================================
*/
User Function AOMS109U(_cFilial, _cPedido)

Local _lRet := .T.
Local _cTipoCar

Begin Sequence
   
   If ! Empty(MV_PAR26)             
	  SC6->(DBSetOrder(1))
      SC6->(DBSeek(_cFilial+_cPedido))
		
      While SC6->(!Eof()) .And. _cFilial == SC6->C6_FILIAL .And. _cPedido == SC6->C6_NUM
         _cTipoCar := Posicione("SB1",1, xFilial("SB1")+SC6->C6_PRODUTO,"B1_TIPCAR") 
         If AllTrim(MV_PAR26) <> AllTrim(_cTipoCar)
            _lRet := .F.
            Break
         EndIf
    	
    	 SC6->(DBSkip())
      EndDo            
   EndIf   
   
End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS109Y()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 24/07/2025
Descrição-------: Rotina Webservice de solicitação de retorno dos Pedidos de Vendas Enviados para o TMS Multiembarcados ou
                  RDC para o Protheus.
Parametros------: oProc = Objeto Regua de Processos.
Retorno---------: Nenhum 
===============================================================================================================================
*/
User Function AOMS109Y(oProc)

Local _lRet   := .F.
Local _aDados := {}
Local _aCabec := {"Filial","Numero PV","Cliente","Loja","Nome","Status"}
Local _lTemDados := .F.
Local _cTitulo := "Resultado da Solicitação de Retorno de Pedidos de Vendas do TMS para o Protheus"

Begin Sequence 

   TRBF->(DBGoTop())

   While ! TRBF->(Eof())
      If ! Empty(TRBF->TRBF_OK)
 
         _lTemDados := .T.

         SC5->(DBGoTo(TRBF->TRBF_REGC5)) 
         
		 If ValType(oproc) == "O"
            oproc:cCaption := ("Processando Pedido de Vendas: "+SC5->C5_NUM+". ")
		    ProcessMessages()
		 EndIf

         If SC5->C5_I_ENVRD <> "S"
			aAdd(_aDados,{SC5->C5_FILIAL, SC5->C5_NUM, SC5->C5_CLIENTE, SC5->C5_LOJACLI, SC5->C5_I_NOME,"Este pedido não se encontra integrado ao sistema TMS !"})
         Else
            If ! U_IT_TMS(SC5->C5_I_LOCEM) 
               FWMsgRun(,{|oproc| _lRet := U_AOMS094E(oproc)},'Aguarde processamento...','Integrando dados solicitação de retorno de PV do TMS para o Protheus...')
            Else
               FWMsgRun(,{|oproc| _lRet := U_AOMS140E(oproc)},'Aguarde processamento...','Integrando dados solicitação de retorno de PV do TMS para o Protheus...')
            EndIf

            If _lRet 
               aAdd(_aDados,{SC5->C5_FILIAL, SC5->C5_NUM, SC5->C5_CLIENTE, SC5->C5_LOJACLI, SC5->C5_I_NOME,"Solicitação de retorno do PV realizada com Sucesso."})
		    Else
		       aAdd(_aDados,{SC5->C5_FILIAL, SC5->C5_NUM, SC5->C5_CLIENTE, SC5->C5_LOJACLI, SC5->C5_I_NOME,"Não foi possível realizar o retorno do PV para o Protheus."})
		    EndIf 
         EndIf 
      EndIf 

	  TRBF->(DBSkip())
   EndDo 
   
   If _lTemDados
      U_ITListBox( _cTitulo , _aCabec , _aDados  ) 
   Else
      U_ITMsg("Nenhum registro selecionado para solicitação de retorno do Pedido de Vendas do TMS para o Protheus.","Atenção",,1)
   EndIf 
   
   TRBF->(DBGoTop())

End Sequence 

Return 

/*
===============================================================================================================================
Programa--------: RetSelecPV()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 28/07/2025
Descrição-------: Ajusta dicinário de perguntas SX1. 
Parametros------: _cPerg = Nome do grupo de perguntas SX1 a ser ajustado.
Retorno---------: Nenhum 
===============================================================================================================================
*/
Static Function RetSelecPV()

Local _aListaPV := {}            

Begin Sequence 
   
   TRBF->( DBGoTop() )

   //================================================================================
   // Armazena todos os pedidos selecionados pelo usuario
   //================================================================================
   
   While TRBF->(!Eof())
	
	  //================================================================================
	  // Somente pedidos selecionados pelo usuario
	  //================================================================================
	  If TRBF->(IsMark( "TRBF_OK" , cMarkado ))
         aAdd(_aListaPV,{TRBF->TRBF_FILIA, TRBF->TRBF_NUM, TRBF->TRBF_REGC5})
	  EndIf
		
  	  TRBF->( DBSkip() )
   EndDo

   TRBF->( DBGoTop() )

End Sequence 

Return _aListaPV
