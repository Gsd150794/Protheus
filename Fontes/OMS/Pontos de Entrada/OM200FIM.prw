#Include "TOTVS.ch"
#Include "RWMAKE.ch"

#Define DS_MODALFRAME	128
#Define TP_GERA_PALET   "1,3,5,6" //"1-Pallet Chep","3-Pallet PBR","4-Pallet Descartavel","5-Pallet Chep Retorno","6-Pallet PBR Retorno"
#Define OBS_PRE_CARGA   "PRE-CARGA - Dados do Transporte serão informados posteriormente. "

Static _cTipo    := Space(1)
Static _cTpCarga := -1
Static _cAuto    := Space(Len(ZZ2->ZZ2_AUTONO))
Static _cCond    := Space(Len(ZZ2->ZZ2_COND))
Static _cObs     := Space(Len(ZZ2->ZZ2_OBS))
Static _cObsCarga:= ""//Space(Len(DAK->DAK_I_OBS)) // Para variavel usada em GET MEMO nao precisa inicia com Space()
Static _nValor   := 0
Static _nPedagio := 0
Static _nFretOL2 := 0
Static _cProtoc  := Space(Len(ZZ2->ZZ2_PAMCAR))
Static _nVlrPam  := 0
Static _cREDP    := Space(Len(DAK->DAK_I_REDP))
Static _cRELO    := Space(Len(DAK->DAK_I_RELO))
Static _cOPER    := Space(Len(DAK->DAK_I_OPER))
Static _cOPLO    := Space(Len(DAK->DAK_I_OPLO))
Static _aLog     := {}
Static _cPreCarga:= "2-Não"//DAK->DAK_I_PREC
Static  _lJob    := IsBlind()

/*
===============================================================================================================================
Programa----------: OM200FIM
Autor-------------: Tiago Correa
Data da Criacao---: 25/01/2009
Descrição---------: Ponto de Entrada no momento da gravacao da Montagem de Carga.
Parametros--------: Padrão
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function OM200FIM(lAcertaCarga)
 
Local aArea := FwGetArea()
Local _aDAI := FwGetArea("DAI")
Local _aSC9 := FwGetArea("SC9")
Local _cTpFroVei, _nRegSC5

Private cCarga 	   := DAK->DAK_COD

If Type("_cMotorDAK") <> "C" .Or. Empty(_cMotorDAK)//Na efetivação da pre-carga vem em branco o DAK e mata o que foi digitado
   Private _cMotorDAK := DAK->DAK_MOTORI
EndIf
If Type("_cCaminDAK") <> "C" .Or. Empty(_cCaminDAK)//Na efetivação da pre-carga vem em branco o DAK e mata o que foi digitado
   Private _cCaminDAK := DAK->DAK_CAMINH
EndIf

DEFAULT lAcertaCarga := .F.

If !(Type("_lAutomatico")) == "L"

   _lAutomatico := .F.

EndIf

// Obtem o tipo de frota de veiculo da carga.
_cTpFroVei :=  Posicione( 'DA3' , 1 , xFilial('DA3')+DAK->DAK_CAMINH , 'DA3_FROVEI' ) // 1=DA3_FILIAL+DA3_COD

// I N I C I O - Tratamento para gravacao dos dados do Frete.

If ! _lAutomatico
   FWMsgRun( , {|| Eval( {|| CalcFrete(lAcertaCarga) } )  },"Aguarde","Gravando dados customizados..."  )

   FWMsgRun( ,{|| OM200Email(.F.) } ,'Aguarde!','Enviando WF ...'  )

   If Len(_aLog) > 0
      _bCancel := {|| MSGSTOP("A montagem de Carga esta Concluida, clique no botão CONFIRMAR.","Atenção! (OM200FIM)") }
      _lRet:=U_ITListBox( 'Log de Geracao de Pedidos de Pallets - Carga: '+cCarga+" (OM200FIM)",;
                           {" ",'Pedido Origem','Pedido Gerado','Movimentacao','Cliente','Operacao','Armazem','Filial Carregamento','Filial Faturamento'} , _aLog , .T. , 4,,,;
                           { 10,             50,             50,           150,      150,        35,       35,                   60,                  60},,,_bCancel )
   EndIf
Else
   CalcFrete(lAcertaCarga)

   OM200Email(.F.)
EndIf

_aLog:= {}

//Código de segurança para garantir que todos os registros no SC9 de pedidos que estão na DAI estão com campos de carga gravados corretamente
DAI->(DBSetOrder(1))
SC9->(DBSetOrder(1))
SC5->(DBSetOrder(1))

If DAI->(DBSeek(DAK->DAK_FILIAL+DAK->DAK_COD))

_nRegSC5 := SC5->(Recno())
While DAI->DAI_FILIAL == DAK->DAK_FILIAL .And. DAI->DAI_COD == DAK->DAK_COD

   // Para frota de veículo própria, atualizar pedido vendas com tipo de frete = "R"
   If ! Empty(_cTpFroVei) .And. _cTpFroVei == "1" // Frota própria
      If SC5->(MsSeek(DAI->DAI_FILIAL+DAI->DAI_PEDIDO))
         SC5->(RecLock("SC5",.F.))
         SC5->C5_TPFRETE := "R" // R=POR CONTA REMETENTE
         SC5->(MSUnLock())
      EndIf
   EndIf

   If SC9->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_PEDIDO))
      While SC9->C9_FILIAL == DAI->DAI_FILIAL .And. SC9->C9_PEDIDO == DAI->DAI_PEDIDO
         SC9->(RecLock("SC9",.F.))

         SC9->C9_CARGA  := DAI->DAI_COD
         SC9->C9_SEQCAR := DAI->DAI_SEQCAR
         SC9->C9_SEQENT := DAI->DAI_SEQUEN

         SC9->(MSUnLock())

         SC9->(DBSkip())
      EndDo

   EndIf

   DAI->(DBSkip())

EndDo

SC5->(DBGoTo(_nRegSC5))

EndIf

FwRestArea(aArea)
DAI->(FwRestArea(_aDAI))
SC9->(FwRestArea(_aSC9))

Return

/*
===============================================================================================================================
Programa----------: TelaFrt ==> OM200Tela()
Autor-------------: Tiago Correa
Data da Criacao---: 25/01/2009
Descrição---------: Gravação dos dados do Frete.
Parametros--------: lEfetiva_Pre_Carga: Se chamou da ações relacionadas é .T. ,
                    _lPreCarga        : se respondeu sim na pergunta é .T.
                    _lScheduller      : .T. informa ser a rotina está sendo rodada via scheduler ou .F. se a rotina é manual.
                    _lSoGeraPallet    : .T. informa ser a rotina está sendo rodada só para gerar Pallet para PV Sedex
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function OM200Tela(lEfetiva_Pre_Carga , _lPreCarga , _lScheduller , _lSoGeraPallet)//Chamada do Rdmake OM200OK.PRW e OM200MNU.PRW

Local _aArea  := FwGetArea()
Local lRetorno:= .F.
Local _nLinha := 15
Local _nPula  := 15
Local _nCol1  := 006
Local _nCol2  := 090
Local _nCol3  := _nCol2+90//75//155
Local _nCol4  := _nCol3+50//205
Local _nCol5  := _nCol2+40
Local _nCol6  := 572//322
Local _nCol7  := _nCol4+75
Local _nCol8  := _nCol7+50
Local _nTamMe := 370//265
Local aCpoBrw := {}

Private _nColOLFOL:=0

DEFAULT lEfetiva_Pre_Carga:= .F.
DEFAULT _lSoGeraPallet:= .F.

aAdd(aCpoBrw,{"PED_PEDIDO",,"Pedido"})
aAdd(aCpoBrw,{{|| If(TRBPED->PED_I_REDP="1","Sim","Nao") },,"Redespacho?"})
nColTR:=Len(aCpoBrw)//Varialvel usada na funcao OM200Marca() para os 2 cliques da coluna
aAdd(aCpoBrw,{"PED_I_TRED",,"Trans Red"})
_nColTRGet:=Len(aCpoBrw)//Varialvel usada na funcao OM200Marca() para os 2 cliques da coluna
aAdd(aCpoBrw,{"PED_I_LTRE",,"Loja Red"})
aAdd(aCpoBrw,{{|| If(TRBPED->PED_I_OPER ="1","Sim","Nao") },,"Oper. Logistico?"})
nColOL:=Len(aCpoBrw)//Varialvel usada na funcao OM200Marca() para os 2 cliques da coluna
aAdd(aCpoBrw,{"PED_I_OPLO",,"Trans Op Log"})
_nColOLGet:=Len(aCpoBrw)//Varialvel usada na funcao OM200Marca() para os 2 cliques da coluna
aAdd(aCpoBrw,{"PED_I_LOPL",,"Loja Op Log"})
If DAK->(FIELDPOS("DAK_I_FROL")) > 0 .And.  DAI->(FIELDPOS("DAI_I_FROL")) > 0
   aAdd(aCpoBrw,{"PED_I_FROL",,"Fret.2o Perc."  ,X3Picture("DAI_I_FROL")  })
   _nColOLFOL:=Len(aCpoBrw)//Varialvel usada na funcao OM200Marca() para os 2 cliques da coluna
EndIf
aAdd(aCpoBrw,{ {|| If(TRBPED->PED_I_TIPC="1","1-Pallet Chep",If(TRBPED->PED_I_TIPC="2","2-Estivada",If(TRBPED->PED_I_TIPC="3","3-Pallet PBR",If(TRBPED->PED_I_TIPC="4","4-Pallet Descartavel",If(TRBPED->PED_I_TIPC="5","5-Pallet Chep Retorno",If(TRBPED->PED_I_TIPC="6","6-Pallet PBR Retorno","            "))))))  },,"Tipo da Carga?"} ) //TP_GERA_PALET
nColTP:=Len(aCpoBrw) //Varialvel usada na funcao OM200Marca() para os 2 cliques da coluna
aAdd(aCpoBrw,{{|| TRBPED->PED_I_QTPA },,"Qtde Pallet","@E 999,999"})
nColQT:=Len(aCpoBrw) //Varialvel usada na funcao OM200Marca() para os 2 cliques da coluna
aAdd(aCpoBrw,{"PED_I_OBPE",,"Observação do Pedido"})
aAdd(aCpoBrw,{{|| If(TRBPED->PED_I_AGEN="A","A-Agendada"  ,If(TRBPED->PED_I_AGEN="I","I-Imediata",If(TRBPED->PED_I_AGEN="S","S-Suspensa",If(TRBPED->PED_I_AGEN="M","M-Agendada Multa","            ")))) },,"Tipo de Agenda"})
aAdd(aCpoBrw,{"PED_CODCLI",,"Cliente"})
aAdd(aCpoBrw,{"PED_LOJA"  ,,"Loja"})
aAdd(aCpoBrw,{"PED_NOME"  ,,"Nome"})
aAdd(aCpoBrw,{"PED_VALOR" ,,"Valor" ,"@E 9,999,999,999."+Replicate("9",TamSX3("DAK_VALOR")[2]) })
aAdd(aCpoBrw,{"PED_PESO"  ,,"Peso"  ,"@E 9,999,999,999."+Replicate("9",TamSX3("DAK_PESO")[2])  })
aAdd(aCpoBrw,{{|| If(Posicione("SC5",1,xFilial("SC5")+TRBPED->PED_PEDIDO,"C5_I_TRCNF")="S","Sim","Não")  },,"Troca Nota"})
aAdd(aCpoBrw,{{|| Posicione("SC5",1,xFilial("SC5")+TRBPED->PED_PEDIDO,"C5_I_PEDPA")  },,"Ped. de Pallet?"})
aAdd(aCpoBrw,{{|| Posicione("SC5",1,xFilial("SC5")+TRBPED->PED_PEDIDO,"C5_I_PEDGE")  },,"Ped. Gerou Pallet?"})
aAdd(aCpoBrw,{{|| Posicione("SC5",1,xFilial("SC5")+TRBPED->PED_PEDIDO,"C5_I_NPALE")  },,"Pedido Pallet"})
aAdd(aCpoBrw,{{|| Posicione("SC5",1,xFilial("SC5")+TRBPED->PED_PEDIDO,"C5_I_OPER")   },,"Tipo Oper."})
aAdd(aCpoBrw,{{|| If(Posicione("SC5",1,xFilial("SC5")+TRBPED->PED_PEDIDO,"C5_I_OPTRI")="R","Remessa","Venda")  },,"Oper Triangular"})//"F=Ped. Venda;R=Ped. Remessa"
aAdd(aCpoBrw,{{|| Posicione("SC5",1,xFilial("SC5")+TRBPED->PED_PEDIDO,"C5_I_PEVIN")   },,"PV Vinculado"})

Private	_aTipoFrete:= { "Autonomo" , "PJ-Transportadora" , "IT-Veiculo Proprio" }
Private _lAutVeic  := .F.
Private oMarkFim
Private _ocRedp
Private _ocReLo
Private _oOper
Private _oOpLo
Private _oFret2
Private _lAutomatico
Private _lVersao12 := .T.//(AllTrim(OAPP:CVERSION) = "12")
Private _nAltCombo :=If(_lVersao12,10,20)
Private _cEstados  := " "//Variavel preenchida para o F3 dos operadores, NÃO RETIRE

If Empty(_lScheduller)
   _lAutomatico := .F. // Rotina rodada manualmente

   Private _AITALAC_F3:={}
   _BSelectZ31:={|| "SELECT DISTINCT Z31_FORNEC, Z31_LOJA, Z31_NOMEFO, Z31_UF, A2_CGC FROM " + RETSQLNAME("Z31")+" Z31, " + RETSQLNAME("SA2") + " SA2  WHERE"+;
                     " Z31_UF  = '"+SC5->C5_I_EST+"' AND "+;
                     " Z31.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' AND Z31_FORNEC = A2_COD AND Z31_LOJA = A2_LOJA ORDER BY Z31_FORNEC, Z31_LOJA " }

   _BSelec2Z31:={|| "SELECT DISTINCT Z31_FORNEC, Z31_LOJA, Z31_NOMEFO, Z31_UF, A2_CGC FROM " + RETSQLNAME("Z31")+" Z31, " + RETSQLNAME("SA2") + " SA2  WHERE"+;
                     " Z31_UF   IN "+ FormatIn( _cEstados , ";" )+" AND "+;
                     " Z31.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' AND Z31_FORNEC = A2_COD AND Z31_LOJA = A2_LOJA ORDER BY Z31_FORNEC, Z31_LOJA " }

   //AD(_aItalac_F3,{"_CAMPO1" ,_cTabela    ,_nCpoChave                                , _nCpoDesc                                             ,_bCondTab, _cTitAux                     , _nTamChv                         , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
   aAdd(_aItalac_F3,{"_cOpPed" ,_BSelectZ31 ,{|Tab| (Tab)->Z31_FORNEC+(Tab)->Z31_LOJA }, {|Tab| (Tab)->A2_CGC+" "+AllTrim((Tab)->Z31_NOMEFO) } ,         ,"Operadores com Transit Time" ,Len(Z31->Z31_FORNEC+Z31->Z31_LOJA),          ,1        ,.F.        ,       , } )
   aAdd(_aItalac_F3,{"_cF3REDP",_BSelec2Z31 ,{|Tab| (Tab)->Z31_FORNEC+(Tab)->Z31_LOJA }, {|Tab| (Tab)->A2_CGC+" "+AllTrim((Tab)->Z31_NOMEFO) } ,         ,"Operadores com Transit Time" ,Len(Z31->Z31_FORNEC+Z31->Z31_LOJA),          ,1        ,.F.        ,       , } )
   aAdd(_aItalac_F3,{"_cF3OPER",_BSelec2Z31 ,{|Tab| (Tab)->Z31_FORNEC+(Tab)->Z31_LOJA }, {|Tab| (Tab)->A2_CGC+" "+AllTrim((Tab)->Z31_NOMEFO) } ,         ,"Operadores com Transit Time" ,Len(Z31->Z31_FORNEC+Z31->Z31_LOJA),          ,1        ,.F.        ,       , } )
Else
   _lAutomatico := _lScheduller
EndIf

_cPreCarga := If(_lPreCarga,"1-Sim","2-Não")//DAK->DAK_I_PREC

//Gravo celular do motorista
DA4->(DBSetOrder(1))
If !_lSoGeraPallet .And. !Empty(_cMotorDAK) .And. DA4->(DBSeek(xFilial("DA4")+_cMotorDAK))
   _cDDD := DA4->DA4_DDD
   _cCEL := DA4->DA4_TEL
Else
   _cDDD := Space(Len(DA4->DA4_DDD))
   _cCEL := Space(Len(DA4->DA4_TEL))
EndIf
_cTipo:=_aTipoFrete[1]
If !lEfetiva_Pre_Carga

_bMarcaTRB:=oMark:bAval//Salva os 2 cliques da tela de selecao de Pedidos da Tela anterior para usar para marcar depois que incliir linhas no TRB EVAL(_bMarcaTRB)

If _lPreCarga
   _cTipo:=_aTipoFrete[2]//Forcei 2 na pre-carga por causa das mensagem no estorno da carga do ZZ2 (OS200ES2.PRW)
EndIf

ElseIf !_lSoGeraPallet
   _cObsCarga:=StrTran(AllTrim(Upper(DAK->DAK_I_OBS)),AllTrim(Upper(OBS_PRE_CARGA)),"")
   _nPedagio:=DAK->DAK_I_VRPE
   _cTipo := _aTipoFrete[Val(DAK->DAK_I_TPFR)]
   _cREDP := DAK->DAK_I_REDP
   _cRELO := DAK->DAK_I_RELO
   _cOPER := DAK->DAK_I_OPER
   _cOPLO := DAK->DAK_I_OPLO
   _nValor:= DAK->DAK_I_FRET
   If DAK->(FIELDPOS("DAK_I_FROL")) > 0
      _nFretOL2:=DAK->DAK_I_FROL
   EndIf
   If _lAutomatico
      If !Empty(_cMotorDAK) .And. DAK->DAK_I_TPFR = "1"
         SA2->(DBSetOrder(1))       //DA4 já esta posicionado acima
         If SA2->( DBSeek( xFilial("SA2") + DA4->DA4_FORNEC+DA4->DA4_LOJA ) )
            _cAuto:=SA2->A2_I_AUT
            _cCond:=SA2->A2_COND
         EndIf
      EndIf
   EndIf
EndIf

DBSelectArea("TRBPED")
DbSetFilter({|| PED_MARCA # ' ' }, "PED_MARCA # ' '" )

Private _lTemPalletRetorno:=.F.

If !_lSoGeraPallet
   OM200Pallets()//Inicia os tipos e quantidade dos Pallets e a variavel _lTemPalletRetorno
EndIf

While .T.

   If ! _lAutomatico // Rotina rodada manualmente
      _nLinha := 15
      _cF3REDP:= _cREDP//VariveL Private para o F3 customizado funcionar.
      _cF3OPER:= _cOPER//VariveL Private para o F3 customizado funcionar.

      DEFINE MSDIALOG oTelFrete TITLE "Controle de Frete (OM200FIM)" From 000,000 To 530,1185 Pixel
         @_nLinha,006    Say OemToAnsi( "Tipo de Frete:"	)
         @_nLinha,051 COMBOBOX	oTipo VAR _cTipo	SIZE 070,_nAltCombo COLOR CLR_BLACK ITEMS _aTipoFrete	OF oTelFrete PIXEL

         @_nLinha,_nCol3 Say "Pre - Carga ?"
         @_nLinha,_nCol4 COMBOBOX	_cPreCarga SIZE 040,_nAltCombo COLOR CLR_BLACK ITEMS {"1-Sim","2-Não"} OF oTelFrete PIXEL WHEN !_lPreCarga .And. !lEfetiva_Pre_Carga

         @_nLinha,_nCol7 Say OemToAnsi( "Cod. Autonomo:"	)
         @_nLinha,_nCol8 Get _cAuto	F3 "SA2_08"	Picture "@!"              SIZE 060,021 Valid IIf(Vazio(_cAuto),.T.,VALIDAUT(_cAuto))
         _nLinha+=_nPula

         @_nLinha,006    Say OemToAnsi( "Valor do Frete:"	)
         @_nLinha,051    Get _nValor		    Picture "@E 999,999,999.99" SIZE 060,021 Valid VLDVLPAM( 1 , _nValor , _nVlrPam , _nPedagio)

         @_nLinha,_nCol3 Say "Valor do Pedagio:"
         @_nLinha,_nCol4 Get _nPedagio	    Picture "@E 999,999,999.99"    SIZE 060,021 Valid VLDVLPAM( 3 , _nValor , 0        , _nPedagio)

         @_nLinha,_nCol7 Say OemToAnsi( "Cond. Pagamento:"	)
         @_nLinha,_nCol8 Get _cCond	F3 "SE4"	Picture "@!" SIZE 060,021 Valid IIf(Vazio(_cCond),.T.,ExistCpo("SE4",_cCond))
         _nLinha+=_nPula

         @_nLinha,006    Say OemToAnsi( "Obs. Frete:"		)
         @_nLinha,051    Get _cObs				Picture "@!" SIZE _nTamMe,021
         _nLinha+=_nPula

         @_nLinha,006    Say OemToAnsi( "Obs. Carga:"		)
         @_nLinha,051    GET _cObsCarga MEMO HSCROLL      SIZE _nTamMe,33 PIXEL
         _nLinha+=_nPula+_nPula+10

         @_nLinha,006    Say OemToAnsi( "Prot. Pamcary:"	)
         @_nLinha,_nCol3 Say OemToAnsi( "Valor Pamcary:"	)
         @_nLinha,051    Get _cProtoc Picture "@!"                SIZE 060,021
         @_nLinha,_nCol4 Get _nVlrPam Picture "@E 999,999,999.99"	SIZE 060,021 Valid VLDVLPAM( 2 , _nValor , _nVlrPam )

         _nLinha+=_nPula

         @_nLinha,_nCol1 Say "Transportadora de Redespacho:"
         @_nLinha,_nCol2 msGet _ocredp var _cF3REDP SIZE 033,009 PIXEL OF oTelFrete F3 "F3ITLC"	Valid VLDSA2(_cF3REDP,"TR")                                 Picture "@!"
         @_nLinha,_nCol5 msGet _ocrelo var _cRELO   SIZE 009,009 PIXEL OF oTelFrete             Valid IIf(Vazio(_cF3REDP),.T.,VLDSA2(_cF3REDP+_cRELO,"TR")) Picture "@!"

         @_nLinha,_nCol3 Say "Veiculo:"
         @_nLinha,_nCol4 Get _cCaminDAK F3 "DA3"	Picture "@!" SIZE 060,021 Valid VLDVeiculo(.F.,"VEI") WHEN lEfetiva_Pre_Carga//Só via editar na efetivação pq quando não é precarga digita antes
         If _nColOLFOL > 0
            @_nLinha,_nCol7 Say "Total Frete 2o Percurso:"
            @_nLinha,(_nCol8+15) msGet _oFret2 var _nFretOL2 SIZE 065,009 PIXEL OF oTelFrete Picture X3Picture("DAI_I_FROL") WHEN .F.
         EndIf
         _nLinha+=_nPula

         @_nLinha,_nCol1 Say "Operador Logistico:"
         @_nLinha,_nCol2 msGet _ooper var _cF3OPER	SIZE 033,009 PIXEL OF oTelFrete F3 "F3ITLC"	Valid VLDSA2(_cF3OPER,"OL")                              Picture "@!"
         @_nLinha,_nCol5 msGet _ooplo var _cOPLO	SIZE 009,009 PIXEL OF oTelFrete          	Valid IIf(Vazio(_cF3OPER),.T.,VLDSA2(_cF3OPER+_cOPLO,"OL")) Picture "@!"

         @_nLinha,_nCol3 Say "Motorista:"
         @_nLinha,_nCol4 Get _cMotorDAK F3 "DA4"	Picture "@!" SIZE 060,021 Valid VLDVeiculo(.F.,"MOTO") WHEN lEfetiva_Pre_Carga//Só via editar na efetivação pq quando não é precarga digita antes

         @_nLinha,_nCol7 Say "DDD / Celular:"
         @_nLinha,_nCol8    msGet _cDDD SIZE 010,009 PIXEL OF oTelFrete Picture "99"			Valid NaoVazio(_cDDD) WHEN !Empty(_cMotorDAK)
         @_nLinha,_nCol8+15 msGet _cCEL SIZE 036,009 PIXEL OF oTelFrete Picture "999999999"	Valid NaoVazio(_cCEL) WHEN !Empty(_cMotorDAK)

         _nLinha+=15

         @_nLinha    ,_nCol1 Say "Clique 2 vezes na linha e coluna para: Alterar entre Sim e Não, Escolher o Rededespacho e o Operador Logistico , Escolher o Tipo da Carga e Digitar a Quantidade de Pallet e Valor do Frete 2o percurso abaixo:"
         _nLinha+=10

         DBSelectArea("TRBPED")
         DBGoTop()
         oMarkFim:=MsSelect():New("TRBPED",,,aCpoBrw,.F.,,{_nLinha,_nCol1,(_nLinha+85),  _nCol6 })
         oMarkFim:bAval:= {|| OM200Marca(oMarkFim:oBrowse,lEfetiva_Pre_Carga,aCpoBrw) }
         oMarkFim:oBrowse:lhasMark    := .T.
         oMarkFim:oBrowse:lCanAllmark := .T.

         _nLinha+=90

         @005,003 To _nLinha,(_nCol6+3) Title OemToAnsi("Informações do Frete")

         _nLinha+=02
            @ _nLinha,(_nCol6-400) Button OemToAnsi("OK") Size 36,16 Action	(IIf(ValidaTela( _cTipo , _cAuto , _nValor , _cCond ,  , _cDDD , _cCEL ) .AND.;
                                                                                                         VLDSA2(_cF3REDP+_cRELO,"OKTR") .AND.;
                                                                                                         VLDSA2(_cF3OPER+_cOPLO,"OKOL") .AND.;
                                                                                                         VLDSA2(_cF3OPER+_cOPLO,"OKTD") .AND.;
                                                                                                         VLDSA2("","OKTELA") .And. VLDVeiculo(.T.),;
                                                                                                         (oTelFrete:End(),lRetorno:=.T.),)	)

         @ _nLinha,(_nCol6-100) Button OemToAnsi("Ver Pedido") Size 36,16 Action	(U_IT_VisuPV(TRBPED->PED_PEDIDO))

         @ _nLinha,(_nCol6-250) Button "Cancela	" Size 36,16 Action	(oTelFrete:End(),lRetorno:=.F.)

      ACTIVATE MSDIALOG oTelFrete CENTERED

      _cREDP := _cF3REDP//Volta o valor para a Staticas
      _cOPER := _cF3OPER//Volta o valor para a Staticas

   Else // Rotina rodada via Scheduller
      lRetorno := .T.
   EndIf

   If lRetorno
      _aPeds_Pallet:= {}
      _aLog        := {}
      SC5->( DBSetOrder(1) )
      TRBPED->( DBGoTop() )
      While TRBPED->( !Eof() )
         If !SC5->( DBSeek( xFilial("SC5") + TRBPED->PED_PEDIDO ) )
            TRBPED->( DBSkip() )
            Loop
         EndIf

         _nRecPedido:=SC5->(RECNO())
         _cCodPedPallet:=SC5->C5_I_NPALE

         If !Empty(_cCodPedPallet) .And. SC5->( DBSeek( xFilial("SC5") + _cCodPedPallet ) )//Se acho é pq já tem Pedido de Pallet vinculado
            TRBPED->( DBSkip() )
            Loop
         EndIf

         If TRBPED->PED_I_TIPC $ TP_GERA_PALET .And. !Empty(TRBPED->PED_I_QTPA)
            //                   1-Recno do SC5 , 2-Recno do TRB
            aAdd(_aPeds_Pallet, { _nRecPedido, TRBPED->(Recno() ),0,;//3-Recno do Pedido Novo de Pallet
                                                            "Local",;//4-Local do Pedido do Pallet
                                                                  0,;//5-Recno do Item do Pedido Novo de Pallet
                                    TRBPED->PED_PEDIDO,_cCodPedPallet})//Numero dos Pedido para ajudar no DEBUG
         EndIf
         TRBPED->( DBSkip() )
      EndDo

      _lGerouOK := .T.//Private tratada dentro de todas as funções abaixo e usada em programas que chamam essa função U_OM200Tela()
      lAcertaCarga:=.F.

      If Len(_aPeds_Pallet) > 0
         BEGIN Transaction
            If ! _lAutomatico // Rotina rodada manualmente
               FWMsgRun( ,{|oproc| _lGerouOK := GeraPedPallet(_aPeds_Pallet,,oproc) } ,"Aguarde", "Gerando Pedidos de Pallet..." )

               FWMsgRun( ,{|oproc| LiberaPedPallCarga(_aPeds_Pallet,,oproc) } ,'Aguarde', "Liberando Pedidos de Pallet..." )

               If _lGerouOK
                  lAcertaCarga:=lEfetiva_Pre_Carga//Só acerta a Carga de se gerou Pallet na Efetivação da Pre-Carga
                  FWMsgRun( ,{|oproc| IncliPedPallCarga(_aPeds_Pallet,lEfetiva_Pre_Carga,,oproc) } ,'Aguarde', "Incluindo Pedidos de Pallets..." )
               EndIf
            Else // Rotina rodada via Scheduller
               _lGerouOK := GeraPedPallet(_aPeds_Pallet,_lAutomatico)

               LiberaPedPallCarga(_aPeds_Pallet,_lAutomatico)

               If _lGerouOK .And. !_lSoGeraPallet
                  lAcertaCarga:=lEfetiva_Pre_Carga//Só acerta a Carga de se gerou Pallet na Efetivação da Pre-Carga
                  IncliPedPallCarga(_aPeds_Pallet,lEfetiva_Pre_Carga,_lAutomatico)
                  EndIf
               EndIf

            If !_lGerouOK
               DisarmTransaction()
            EndIf
         END Transaction
      EndIf

      If ! _lAutomatico // Rotina rodada manualmente
         If Len(_aLog) > 0 .And. !_lGerouOK
            _cProblema:="Ocorreram problemas na Geração de Pedidos de Pallet, para maiores detalhes veja a Coluna Movimentação."
            _cSolucao :="Para fechar a tela de Log clique no Botão FECHAR. Todas as Movimentações não poderam ser salvas."
            _bOK:={|| U_ITMsg(_cProblema,"Atenção!",_cSolucao,1) , .F. }

            _lRet:=U_ITListBox( 'Log de Geracao de Pedidos de Pallets (OM200FIM)' ,;
                                 {" ",'Pedido Origem','Pedido Gerado','Movimentação','Cliente','Operacao','Armazem','Filial Carregamento','Filial Faturamento'} , _aLog , .T. , 4,,,;
                                 { 10,             50,             50,           150,      150,        35,       35,                   60,                  60},, _bOK  , )
            Loop
         EndIf
      Else
         _aLogGerPal:=ACLONE(_aLog)//Variavel usada no M460MARK.PRW

         If Len(_aLog) > 0 .And. !_lGerouOK
            lRetorno := .F.
            Exit//Loop
         EndIf
      EndIf

      If !_lSoGeraPallet
         //Gravo celular do motorista
         DA4->(DBSetOrder(1))
         If DA4->(DBSeek(xFilial("DA4")+_cMotorDAK))
               DA4->(RecLock("DA4", .F.))
               DA4->DA4_DDD:=_cDDD
               DA4->DA4_TEL:=_cCEL
               DA4->(MSUnLock())
         EndIf
         //Gravo celular do motorista

         If _cPreCarga = "1"
               _cObsCarga:=OBS_PRE_CARGA+AllTrim(_cObsCarga)
         EndIf

         If lEfetiva_Pre_Carga
               U_OM200FIM(lAcertaCarga)//Grava os dados e envia o e-mail
         EndIf
      EndIf

   ElseIf lEfetiva_Pre_Carga//Limpa os campos PQ na tela de efetivar pré-carga tem o botão cancela e o usuario pode ter preecnhidos todas as variaveis
      //Limpa os campos
      _cTipo     := Space(1)
      _cAuto     := Space(Len(ZZ2->ZZ2_AUTONO))
      _cCond     := Space(Len(ZZ2->ZZ2_COND))
      _cObs	     := Space(Len(ZZ2->ZZ2_OBS))
      _cObsCarga := ""// - Para variavel usada em GET MEMO nao precisa inicia com Space()
      _nValor    := 0
      _nPedagio  := 0
      _cProtoc   := Space(Len(ZZ2->ZZ2_PAMCAR))
      _nVlrPam   := 0
      _cREDP     := Space(Len(DAK->DAK_I_REDP))
      _cRELO     := Space(Len(DAK->DAK_I_RELO))
      _cOPER     := Space(Len(DAK->DAK_I_OPER))
      _cOPLO     := Space(Len(DAK->DAK_I_OPLO))
      _cPreCarga := "2-Não"//DAK->DAK_I_PREC
   EndIf//lRetorno

   Exit
EndDo

DBSelectArea("TRBPED")
dbClearFilter()
DBGoTop()

If ! _lAutomatico // Rotina rodada manualmente
   If !lEfetiva_Pre_Carga
      oMark:oBrowse:Refresh()
   EndIf
EndIf

FwRestArea(_aArea)

Return lRetorno

/*
===============================================================================================================================
Programa----------: ValidaTela
Autor-------------: Tiago Correa
Data da Criacao---: 25/01/2009
Descrição---------: Funcao para validar Tela de Preenchimento do Frete na Montagem da Carga.
Parametros--------: _cTipo,_cAuto,_nValor,_cCond
Retorno-----------: .T. = Validacao OK permitindo o andamento da rotina
------------------: .F. = Validacao Negada nao permitindo o andamento da rotina
===============================================================================================================================
*/
Static Function ValidaTela( _cTipo , _cAuto , _nValor , _cCond , _cTpCarga , _cDDD , _cCEL )

Local _lRet	 := .T.
Local _cCamposOb:= ""
Local _cQuery	 := ""
Local _oAliasDA4:= GetNextAlias()
Local _cCodForn := ""
Local _cAliasAut:= GetNextAlias()
Local oButton1  := NIL
Local oButton2  := NIL
Local oSay1	 := NIL
Local oSay2	 := NIL
Local oSay3	 := NIL
Local _oDlgMsg	 := NIL

If _cPreCarga = "1"//DAK->DAK_I_PREC
   Return .T.
EndIf

IIf( Empty(_cTipo) , _cCamposOb +=  "Tipo de Frete " , NIL )

//Verifica se o usuario nao fornececeu um veiculo na montagem da carga, neste
//caso somente podera ser escolhido o tipo de Frete veiculo proprio
If Empty(_cCaminDAK) .And. Upper(_cTipo) <> "IT-VEICULO PROPRIO"
   U_ITMsg('É necessário informar um veículo para a montagem da Carga atual.',;
            "Validação Veiculo",'Caso não seja fornecido um veículo deve ser utilizado o Tipo de Frete como sendo:IT-VEICULO PROPRIO'+SubStr(_cCodForn,1,1),1)
   Return( .F. )
EndIf

If Empty( _cTipo ) .Or. !Empty( _cCamposOb )
   U_ITMsg('Existe(m) campo(s) obrigatório(s) que não foi(ram) preenchido(s)!'	,;
            "Validação Campos",'Verifique o preenchimento do(s) campo(s): ' + SubStr( _cCamposOb , 1 , Len(_cCamposOb) - 1 ),1)
   Return( .F. )
EndIf

If Upper(_cTipo) == "AUTONOMO"
   If Empty(_cAuto) .Or. Empty(_nValor) .Or. Empty(_cCond)
      _lRet := .F.
      U_ITMsg('Existe(m) campo(s) obrigatório(s) que não foi(ram) preenchido(s)!'	,;
            "Validação Campos",'Verifique o preenchimento do(s) campo(s): ' + ' VALOR DO FRETE, COD. AUTONOMO, COND. PAGAMENTO',1)
   EndIf
ElseIf Upper(_cTipo) == "PJ-TRANSPORTADORA"
   If Empty(_nValor)
      _lRet := .F.
      U_ITMsg('Existe(m) campo(s) obrigatório(s) que não foi(ram) preenchido(s)!'	,;
         "Validação Campos",'Verifique o preenchimento do(s) campo(s): ' + ' VALOR DO FRETE' ,1)
   EndIf
ElseIf Upper(_cTipo) == "IT-VEICULO PROPRIO"
   If !Empty(_nValor)
      _lRet := .F.
      U_ITMsg('Falha no preenchimento dos campos do formulário atual! '	,;
         "Validação Campos",'O campo Valor do Frete deve permanecer em branco quando o transporte For definido como Veículo Próprio.' ,1)
   EndIf
Else
   _lRet := .F.
   U_ITMsg('Existe(m) campo(s) obrigatório(s) que não foi(ram) preenchido(s)!'	,;
         "Validação Campos",'Verifique o preenchimento do(s) campo(s): ' + ' TIPO DO FRETE' ,1)
EndIf

// Validacoes para constatar se o veiculo(Transportadora) informado condiz com
// o tipo informado na tela de Frete
If _lRet .And. ( Upper(_cTipo) == "AUTONOMO" .Or. Upper(_cTipo) == "PJ-TRANSPORTADORA" )
   // CASO NAO ENCONTRE CARGA PARA ESTORNAR, VERIFICAR SE É DE AUTONOMO
   _cQuery := " SELECT "
   _cQuery += " 	DA4_FORNEC , "
   _cQuery += "	DA4_LOJA "
   _cQuery += " FROM " + RetSqlName("DA4")
   _cQuery += " WHERE "
   _cQuery += " 		D_E_L_E_T_	= ' ' "
   _cQuery += " AND	DA4_COD		= '"+ _cMotorDAK +"' "

   If !Empty( xFilial("DA4") )
      _cQuery += " AND	DA4_FILIAL	= '"+ xFilial("DA4") +"' "
   EndIf

   MPSysOpenQuery( _cQuery , _oAliasDA4)

   _cCodForn := (_oAliasDA4)->DA4_FORNEC

   (_oAliasDA4)->(DBCloseArea())

   If SubStr(_cCodForn,1,1) == 'A' .And. Upper(_cTipo) <> "AUTONOMO"
      _lRet := .F.
      U_ITMsg('Foi informado um Tipo de Frete diferente do Fornecedor associado ao veículo na montagem da carga!'	,;
               "Validação Campos",'O tipo de Fornecedor escolhido é: '+ SubStr(_cCodForn,1,1)+"-Autonomo, portanto o tipo do Frete deve ser Autonomo." ,1)
   ElseIf (SubStr(_cCodForn,1,1) == 'T' .Or. SubStr(_cCodForn,1,1) == 'G') .And. Upper(_cTipo) <> "PJ-TRANSPORTADORA"
      _lRet := .F.
      U_ITMsg('Foi informado um Tipo de Frete diferente do Fornecedor associado ao veículo na montagem da carga!'	,;
               "Validação Campos",'O tipo de Fornecedor escolhido é: '+ SubStr(_cCodForn,1,1)+", portanto o tipo do Frete deve ser PJ-Transportadora."  ,1)
   EndIf
EndIf

//Verifica se o autonomo ligado ao motorista informado no veiculo é o mesmo que
//foi informado no frete
If _lRet .And. !_lAutVeic .And. Upper(_cTipo) == "AUTONOMO"
   _cQuery := " SELECT"
   _cQuery += " 	SA2.A2_I_AUT , "
   _cQuery += " 	SRA.RA_NOMECMP "
   _cQuery += " FROM "+ RetSqlName("DA4") +" DA4 "
   _cQuery += " JOIN "+ RetSqlName("SA2") +" SA2 ON SA2.A2_COD = DA4.DA4_FORNEC AND SA2.A2_LOJA = DA4.DA4_LOJA "
   _cQuery += " JOIN "+ RetSqlName("SRA") +" SRA ON SRA.RA_MAT = SA2.A2_I_AUT "
   _cQuery += " WHERE "
   _cQuery += " 		DA4.D_E_L_E_T_	= ' ' "
   _cQuery += " AND	SA2.D_E_L_E_T_	= ' ' "
   _cQuery += " AND	SRA.D_E_L_E_T_	= ' ' "
   _cQuery += " AND	DA4.DA4_COD		= '"+ _cMotorDAK +"' "

   MPSysOpenQuery( _cQuery , _cAliasAut)

   (_cAliasAut)->( DBGoTop() )

   If (_cAliasAut)->( !Eof() )
      If (_cAliasAut)->A2_I_AUT != _cAuto
         DEFINE MSDIALOG _oDlgMsg TITLE "ATENCAO" FROM 000, 000  TO 170, 500 COLORS 0, 16777215 PIXEL Style DS_MODALFRAME
               _oDlgMsg:LESCCLOSE := .F.

               @059,028 BUTTON oButton1	PROMPT "Sim" ACTION Eval({|| _lRet		:= .F. , _oDlgMsg:End() 				} )				   SIZE 037, 015 OF _oDlgMsg PIXEL
               @059,185 BUTTON oButton2	PROMPT "Nao" ACTION Eval({|| _lAutVeic	:= .T. , _lRet := .T. , _oDlgMsg:End()	} )	   	   SIZE 037, 015 OF _oDlgMsg PIXEL
               @015,012 Say oSay1			PROMPT "O veículo associado na montagem da carga esta associado ao autônomo:"					   SIZE 229, 007 OF _oDlgMsg PIXEL COLORS 0, 16777215
               @027,012 Say oSay2			PROMPT (_cAliasAut)->A2_I_AUT + '-' + SubStr(AllTrim((_cAliasAut)->RA_NOMECMP),1,25)			SIZE 229, 007 OF _oDlgMsg PIXEL COLORS 0, 16777215
               @040,012 Say oSay3			PROMPT "que difere do informado para geração do RPA. Deseja modificar o autônomo informado?"	SIZE 229, 007 OF _oDlgMsg PIXEL COLORS 0, 16777215
         ACTIVATE MSDIALOG _oDlgMsg CENTERED
      EndIf
   EndIf
   (_cAliasAut)->( DBCloseArea() )
EndIf

// Valida se o cadastro do fornecedor contem o autonomo indicado
If Upper(_cTipo) == "AUTONOMO" .And. _lRet
   SA2->( DBOrderNickName("IT_AUTONOM") )
   If !( SA2->( DBSeek( xFilial("SA2") + _cAuto ) ) )
      SA2->( DBOrderNickName("IT_AUTAVUL") )
      If !( SA2->( DBSeek( xFilial("SA2") + _cAuto ) ) )
         _lRet := .F.
         U_ITMsg('Foi encontrado um problema no cadastro do Fornecedor associado ao veículo na Carga!' + CHR(10) + CHR(13) + ;
         'O autônomo selecionado não está amarrado à um cadastro de Fornecedor válido!' 	,;
         "Validação Campos",'Verificar os dados e tentar novamente.' ,1)
      EndIf
   EndIf
EndIf
SA2->(DBSetOrder(1))

If _lRet .And. (Empty(_cDDD) .Or. Empty(_cCEL))
   _lRet := .F.
   U_ITMsg('É obrigatório o preenchimento dos campos DDD e/ou Celular.',;
         "Validação Campos",'Favor preencher os campos corretamente e tente salvar novamente o registro!' ,1)
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: CalcFrete
Autor-------------: Tiago Correa
Data da Criacao---: 25/01/2009
Descrição---------: Funcao para realizar o Calculo Geral do Recibo de Autonomos e gravar nas tabelas os dados do cálculo
Parametros--------: lAcertaCarga As Logical
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CalcFrete(lAcertaCarga As Logical)

Local _cTipoFret:= "" As Char
Local nSeqInc   := SuperGetMV("MV_OMSENTR",.F.,5) As numeric
Local nInc      := 0 As numeric
Local _nTotPeso := 0 As numeric

Private _cRecibo	   := ""
Private _nVlrIrrfPag:= 0
Private _nTeto      := 0
Private _nbaseSest  := 0
Private _nVlrSest   := 0
Private _nbaseinss  := 0
Private _nVlrInss   := 0
Private _nVlrIrrf   := 0
Private _x08_Lim3   := NIL
Private _x08_Lim3P  := NIL
Private _x09_rend1  := NIL
Private _x09_rend2  := NIL
Private _x09_rend3  := NIL
Private _x09_rend4  := NIL
Private _x09_rend5  := NIL
Private _x09_aliq2  := NIL
Private _x09_aliq3  := NIL
Private _x09_aliq4  := NIL
Private _x09_aliq5  := NIL
Private _x09_parc2  := NIL
Private _x09_parc3  := NIL
Private _x09_parc4  := NIL
Private _x09_parc5  := NIL
Private _x09_deddep := NIL
Private _x09_limdep := NIL
Private _x09_retmin := NIL

If Upper( AllTrim( _cTipo ) ) == "AUTONOMO" .And. _cPreCarga # "1"
   //Grava o cabecalho do recibo
   _cRecibo := CRIAVAR("ZZ2_RECIBO")

   If ( __lSX8 )
      ConfirmSX8()
   EndIf

   ZZ2->( RecLock("ZZ2" , .T. ) )

   ZZ2->ZZ2_FILIAL  := xFilial("ZZ2")
   ZZ2->ZZ2_RECIBO  := _cRecibo
   ZZ2->ZZ2_CARGA   := cCarga
   ZZ2->ZZ2_AUTONO  := _cAuto
   ZZ2->ZZ2_COND    := _cCond
   ZZ2->ZZ2_TOTAL   := _nValor
   ZZ2->ZZ2_SEST    := _nVlrSest
   ZZ2->ZZ2_INSS    := _nVlrInss
   ZZ2->ZZ2_IRRF    := _nVlrIrrf
   ZZ2->ZZ2_DATA    := dDataBase
   ZZ2->ZZ2_TIPAUT  := "1"
   ZZ2->ZZ2_OBS     := AllTrim(_cObs)
   ZZ2->ZZ2_PAMCAR  := AllTrim(_cProtoc)
   ZZ2->ZZ2_PAMVLR  := _nVlrPam
   ZZ2->ZZ2_ORIGEM  := "1"
   ZZ2->ZZ2_VRPEDA  := _nPedagio

   ZZ2->( MSUnLock() )

EndIf

_nTotPeso :=0
Private _nTotValor:=0//Somado dentro da função U_ITAcertaPeso ()
_nFretOL2 :=0//variavel Statica
SC5->( DBSetOrder(1) )
SC6->( DBSetOrder(1) )

_aCliente:={}//Para contar os pontos de atendimento
DAI->( DBSetOrder(4) )//DAI_FILIAL+DAI_PEDIDO+DAI->DAI_COD+DAI_SEQCAR
DBSelectArea("TRBPED")
DbSetFilter({|| TRBPED->PED_GERA = "S" }, "TRBPED->PED_GERA = 'S'" )
DBGoTop()
nSequencia:=0
_cFilFatTrocaNF:=""
_lGralogPeso:=SuperGetMV("IT_GVLOGPE",.F., .T.) // Verifica se é necessário gravar log de alteração de carga
_cTexto:="DADOS DA CARGA: "+DAK->DAK_FILIAL+"-"+DAK->DAK_COD+CRLF
_cDados:=""

While !TRBPED->(Eof())
   If DAI->( DBSeek( xFilial("DAI")  + TRBPED->PED_PEDIDO + DAK->DAK_COD + DAK->DAK_SEQCAR  ) ) .AND.;
      SC5->( DBSeek( DAI->DAI_FILIAL + TRBPED->PED_PEDIDO ) )
      _cDados:=""//Grava dentro da função U_ITAcertaPeso()
      _nPesoBrut:=U_ITAcertaPeso(DAI->DAI_FILIAL + DAI->DAI_PEDIDO)//Acerta o peso dos pedidos e soma o  _nTotValor
      _cTexto+="**ACERTOS U_ITACERTAPESO : "+DAI->DAI_FILIAL+"-"+DAI->DAI_PEDIDO+CRLF+_cDados
      _cTexto+="*DAI antes.: DAI_PESO: " + Str(DAI->DAI_PESO,19,5) +CRLF

      If Empty(_cFilFatTrocaNF) .And. SC5->C5_I_TRCNF = 'S' .And. !Empty(SC5->C5_I_FILFT) .And. !Empty(SC5->C5_I_FLFNC) .AND.;
                                             SC5->C5_I_FILFT # SC5->C5_I_FLFNC .And. Empty(SC5->C5_I_PDPR+SC5->C5_I_PDFT)//Pedidos de Troca Nota
         _cFilFatTrocaNF:= SC5->C5_I_FILFT
      EndIf

      DAI->( RecLock( "DAI" , .F. ) )
      DAI->DAI_I_REDP:=If(Empty(TRBPED->PED_I_REDP),"2",TRBPED->PED_I_REDP)
      DAI->DAI_I_OPER:=If(Empty(TRBPED->PED_I_OPER),"2",TRBPED->PED_I_OPER)
      DAI->DAI_I_OPLO:=If(Empty(TRBPED->PED_I_OPLO),"",TRBPED->PED_I_OPLO)
      DAI->DAI_I_LOPL:=If(Empty(TRBPED->PED_I_LOPL),"",TRBPED->PED_I_LOPL)
      DAI->DAI_I_TRED:=If(Empty(TRBPED->PED_I_TRED),"",TRBPED->PED_I_TRED)
      DAI->DAI_I_LTRE:=If(Empty(TRBPED->PED_I_LTRE),"",TRBPED->PED_I_LTRE)
      DAI->DAI_I_TIPC:=TRBPED->PED_I_TIPC
      DAI->DAI_I_QTPA:=TRBPED->PED_I_QTPA
      If DAI->(FIELDPOS("DAI_I_FROL")) > 0 .And. (DAI->DAI_I_OPER = "1" .Or.  DAI->DAI_I_REDP = "1")
         DAI->DAI_I_FROL:=TRBPED->PED_I_FROL
      EndIf
      
      DAI->DAI_PESO:=_nPesoBrut //#Regrava por segurança U_ITAcertaPeso
      _nTotPeso    +=DAI->DAI_PESO
      _cTexto+="*DAI depois: DAI_PESO: " + Str(DAI->DAI_PESO,19,5) +CRLF
      
      If Empty(DAI->DAI_DTCHEG)//Para os Pedidos de Pallets que vem com esse campos vazios
         DAI->DAI_DTCHEG := Date()
         DAI->DAI_TMSERV := '0000:00'
         DAI->DAI_CHEGAD := '08:00'
         DAI->DAI_DTSAID := Date()
         DAI->DAI_DATA   := Date()
         DAI->DAI_HORA   := Time()
      EndIf
      DAI->( MSUnLock() )

      nSequencia+= nSeqInc//Reconta a sequencia para continuar na inclusao de pedidos de pallet abaixo

      _cChave  := DAI->( DAI_CLIENT + DAI_LOJA )
      If DAI->DAI_I_OPER="1" .And. !Empty(DAI->DAI_I_OPLO)
         _cChave  := DAI->DAI_I_OPLO+DAI->DAI_I_LOPL
      EndIf
      If DAI->DAI_I_REDP="1" .And. !Empty(DAI->DAI_I_TRED)
         _cChave  := DAI->DAI_I_TRED+DAI->DAI_I_LTRE
      EndIf
      If !Empty(_cChave) .And. aScan(_aCliente,_cChave) = 0
         aAdd(_aCliente,_cChave)//Acerta a contagem de ponto de entrega do padrao ABAIXO
      EndIf
      If DAI->(FIELDPOS("DAI_I_FROL")) > 0 .And. (DAI->DAI_I_OPER = "1" .Or.  DAI->DAI_I_REDP = "1")
         _nFretOL2 += DAI->DAI_I_FROL//Soma o frete do 2 Percurso para gravar no DAK_I_FROL
      EndIf
   ElseIf TRBPED->(FIELDPOS("PED_RECDAI")) > 0 .And. TRBPED->PED_RECDAI > 0 // SÓ EFETIVAÇÃO DA PRE-CARGA
      // Inserindo Pedido de Pallets criados na efetivação da pre-carga
      DAI->(DBGoTo(TRBPED->PED_RECDAI))

      For nInc := 1 To DAI->(FCount())
            M->&(DAI->(FieldName(nInc))) := DAI->(FieldGet(nInc))
      Next nInc

      nSequencia    += nSeqInc
      M->DAI_PEDIDO := TRBPED->PED_PEDIDO
      M->DAI_CLIENT := TRBPED->PED_CODCLI
      M->DAI_LOJA   := TRBPED->PED_LOJA
      M->DAI_PESO   := TRBPED->PED_PESO
      M->DAI_I_REDP := TRBPED->PED_I_REDP
      M->DAI_I_OPER := TRBPED->PED_I_OPER
      M->DAI_I_OPLO := TRBPED->PED_I_OPLO
      M->DAI_I_LOPL := TRBPED->PED_I_LOPL
      M->DAI_I_TRED := TRBPED->PED_I_TRED
      M->DAI_I_LTRE := TRBPED->PED_I_LTRE
      M->DAI_I_TIPC := TRBPED->PED_I_TIPC
      M->DAI_I_QTPA := TRBPED->PED_I_QTPA
      M->DAI_DTCHEG := Date()
      M->DAI_TMSERV := '0000:00'
      M->DAI_CHEGAD := '08:00'
      M->DAI_DTSAID := Date()
      M->DAI_DATA   := Date()
      M->DAI_HORA   := Time()
      M->DAI_SEQUEN := StrZero(nSequencia,6)
      If TRBPED->(FIELDPOS("PED_I_FROL")) > 0
         M->DAI_I_FROL := TRBPED->PED_I_FROL
      EndIf

      DAI->(RecLock("DAI",.T.))
      AvReplace("M", "DAI")
      DAI->(MSUnLock())
   EndIf
   TRBPED->(DBSkip())
EndDo

TRBPED->(DBGoTop())
SC5->( DBSeek( xFilial("SC5") + TRBPED->PED_PEDIDO ) )//PARA GRAVAR O CAMPO DAK->DAK_I_LEMB COM SC5->C5_I_LOCEM

DAI->( DBSetOrder(1) )//DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
DBSelectArea("TRBPED")
dbClearFilter()
DBGoTop()

// Armazena o tipo da carga
DAK->( DBSetOrder(1) ) //DAK_FILIAL+DAK_COD+DAK_SEQCAR
If DAK->( DBSeek( xFilial("DAK") + cCarga ) )
   Do Case
      Case Upper(AllTrim(_cTipo)) == "PJ-TRANSPORTADORA" .Or. _cPreCarga = "1"//Forcei 2 na pre-carga por causa das mensagem no estorno da carga do ZZ2 (OS200ES2.PRW)
         _cTipoFret:= "2"
      Case Upper( AllTrim(_cTipo) ) == "AUTONOMO"
         _cTipoFret := "1"
      OtherWise
         _cTipoFret:= "3"
   EndCase

   DAK->( RecLock( "DAK" , .F. ) )
   DAK->DAK_I_TPFR := _cTipoFret
   DAK->DAK_I_REDP := _cREDP
   DAK->DAK_I_RELO := _cRELO
   DAK->DAK_I_OPER := _cOPER
   DAK->DAK_I_OPLO := _cOPLO
   DAK->DAK_I_OBS  := AllTrim(_cObsCarga)
   DAK->DAK_I_VRPE := _nPedagio
   If DAK->(FIELDPOS("DAK_I_FROL")) > 0
      DAK->DAK_I_FROL := _nFretOL2
   EndIf
   DAK->DAK_I_LEMB := SC5->C5_I_LOCEM // Local de Embarque
   If Len(_aCliente) > 0
      DAK->DAK_PTOENT:=Len(_aCliente)//Acerta a contagem de ponto de entrega do padrao
   EndIf
   DAK->DAK_I_PREC := _cPreCarga
   DAK->DAK_MOTORI := _cMotorDAK
   DAK->DAK_CAMINH := _cCaminDAK
   _cTexto+="***DAK antes.: DAK_PESO: " + Str(DAK->DAK_PESO,19,5) +CRLF
   DAK->DAK_PESO   := _nTotPeso // Somado dentro da função U_ITAcertaPeso ()
   _cTexto+="***DAK depois: DAK_PESO: " + Str(DAK->DAK_PESO,19,5) +CRLF
   If lAcertaCarga
      DAK->DAK_VALOR := _nTotValor// Somado dentro da função U_ITAcertaPeso ()
   EndIf
   If DAK->(FIELDPOS( "DAK_I_TRNF" )) > 0
      If !Empty(_cFilFatTrocaNF)
         DAK->DAK_I_TRNF:= "C"            //Preencher o campo com C (Tem troca nota e é filial de carregamento)
         DAK->DAK_I_FITN:= _cFilFatTrocaNF//Filial de faturamento do troca nota (C5_I_FILFT Filial para onde os pedidos de faturamento foram transferidos)
      Else
         DAK->DAK_I_TRNF:= "N"         //Preencher o campo com N
      EndIf
      DAK->DAK_I_INCC:= "N"            //Preencher com N
      DAK->DAK_I_INCF:= "N"            //Preencher com N
   EndIf

   DAK->( MSUnLock() )
EndIf

If _lGralogPeso
   _cdir:="/temp/aoms074/"
   _cFileNome:=_cdir+"om200fim_carga_"+DAK->DAK_FILIAL+"_"+DAK->DAK_COD+"_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".txt"
   MemoWrite(_cFileNome,_cTexto)
EndIf

If  (_cPreCarga # "1" .And. (Upper( AllTrim(_cTipo) ) == "AUTONOMO" .Or. Upper( AllTrim(_cTipo) ) == "PJ-TRANSPORTADORA") .And. _nValor > 0) ;
   .Or. _nPedagio > 0
   GravaFrete( _nValor , cCarga , _nPedagio  )
EndIf

// Limpa os campos para proxima carga
_cTipo	 := Space(1)
_cAuto	 := Space(Len(ZZ2->ZZ2_AUTONO))
_cCond	 := Space(Len(ZZ2->ZZ2_COND))
_cObs	 := Space(Len(ZZ2->ZZ2_OBS))
_cObsCarga:= ""//Para variavel usada em GET MEMO nao precisa inicia com Space()
_nValor	 := 0
_nPedagio:= 0
_cProtoc := Space(Len(ZZ2->ZZ2_PAMCAR))
_nVlrPam := 0
_cREDP   := Space(Len(DAK->DAK_I_REDP))
_cRELO   := Space(Len(DAK->DAK_I_RELO))
_cOPER   := Space(Len(DAK->DAK_I_OPER))
_cOPLO   := Space(Len(DAK->DAK_I_OPLO))
_cPreCarga:= "2-Não"

Return .T.

/*
===============================================================================================================================
Programa----------: CargaRatVlrs
Autor-------------: Alex Wallauer
Data da Criacao---: 14/03/20225
Descrição---------: Refaz o Rateio do valor do PEDAGIO E FRETE 1o PERCURSO / Chamada do programa MOMS010.PRW
Parametros--------: _cCarga As Char
Retorno-----------: GravaFrete ( 0 , _cCarga , 0  )
===============================================================================================================================
*/
User Function CargaRatVlrs(_cCarga As Char)
Return GravaFrete( 0 , _cCarga , 0 )

/*
===============================================================================================================================
Programa----------: GravaFrete
Autor-------------: Tiago Correa
Data da Criacao---: 08/02/2009
Descrição---------: Funcao para gravação do rateiuo do Frete e do Pedagio por item da Carga
Parametros--------: _nDA_I_FRET , _cCarga , _nPedagio
Retorno-----------: .T. ou .F. / Se achou ou não o DAK
===============================================================================================================================
*/
Static Function GravaFrete( _nDA_I_FRET As Numeric , _cCarga as char , _nPedagio As Numeric ) As Logical

Local _nPesoTot     := 0 AS Numeric
Local _nPesoSoPallet:= 0 AS Numeric
Local lAChouDAK     := .F. AS Logical
Local nMaiorVlr     :=0 AS Numeric
Local nMaiorRec     :=0 AS Numeric
Local nVlrSomaPedag :=0 AS Numeric
Local nVlrSomaFrete :=0 AS Numeric

// Gravacao dao Valor total da Carga
DAK->( DBSetOrder(1) ) //DAK_FILIAL+DAK_COD+DAK_SEQCAR
If (lAChouDAK:=DAK->( DBSeek( xFilial("DAK") + _cCarga ) )) .And. _nDA_I_FRET > 0
   DAK->( RecLock( "DAK" , .F. ) )
   DAK->DAK_I_FRET := _nDA_I_FRET
   DAK->( MSUnLock() )

   //Recupera o peso total da carga sem considerar Produtos Unitizadores do PALLET
   _nPesoTot := U_CalPesCarg( _cCarga , 1 )

   //Tratativa se somente foram encontrados produtos PALLET na montagem de carga
   If _nPesoTot == 0
      _nPesoSoPallet := DAK->DAK_PESO
   EndIf

ElseIf lAChouDAK .And. (_nDA_I_FRET = 0  .Or. _nPedagio = 0)//Para quando CHAMA do programa MOMS010.PRW
   _nDA_I_FRET := DAK->DAK_I_FRET
   _nPedagio   := DAK->DAK_I_VRPE

   If (_nPesoTot := U_CalPesCarg( _cCarga , 1 )) = 0
      _nPesoSoPallet:= DAK->DAK_PESO
   EndIf

EndIf

If !lAChouDAK
   Return .F.
EndIf

// Grava Valor Rateado por item da Carga desconsiderando Produtos Unitizadores
DAI->( DBSetOrder(1) ) //DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
If DAI->( DBSeek( xFilial("DAI") + _cCarga ) ) .And. (_nDA_I_FRET > 0 .Or. _nPedagio > 0)
   While DAI->(!Eof()) .And. DAI->DAI_COD == _cCarga .And. DAI->DAI_FILIAL == xFilial("DAI")
      DAI->( RecLock( "DAI" , .F. ) )
      // Caso a carga possua Produtos acabados mais pedidos de PALLET sera rateado o
      // frete somente por Pedidos que nao sejam de PALLET
      If _nPesoTot > 0
         If U_CalPesCarg(DAI->DAI_PEDIDO,2) > 0
               DAI->DAI_I_FRET:=	((_nDA_I_FRET  / _nPesoTot)	*	DAI->DAI_PESO)
               If DAI->(FIELDPOS("DAI_I_VRPE")) > 0
                  DAI->DAI_I_VRPE:=	((_nPedagio / _nPesoTot)	*	DAI->DAI_PESO)
               EndIf
         EndIf

      // Caso a montagem de carga somene possua pedidos de PALLET
      Else
         DAI->DAI_I_FRET:=	( ( _nDA_I_FRET / _nPesoSoPallet ) * DAI->DAI_PESO )
         If DAI->(FIELDPOS("DAI_I_VRPE")) > 0
            DAI->DAI_I_VRPE:=	( ( _nPedagio   / _nPesoSoPallet ) * DAI->DAI_PESO )
         EndIf
      EndIf

      If DAI->DAI_PESO > nMaiorVlr
         nMaiorVlr:=DAI->DAI_PESO
         nMaiorRec:=DAI->(RecNo())
      EndIf
      nVlrSomaFrete+=DAI->DAI_I_FRET
      If DAI->(FIELDPOS("DAI_I_VRPE")) > 0
         nVlrSomaPedag+=DAI->DAI_I_VRPE
      EndIf

      DAI->( MSUnLock() )

      DAI->( DBSkip() )
   EndDo
EndIf

// Acertos de diferenças de frete e pedagio
If nMaiorRec > 0  .And. (nVlrSomaFrete <> _nDA_I_FRET .Or. nVlrSomaPedag <> _nPedagio)
   DAI->( DBGoTo(nMaiorRec))
   DAI->( RecLock( "DAI" , .F. ) )
   If nVlrSomaFrete <> _nDA_I_FRET
      DAI->DAI_I_FRET:= DAI->DAI_I_FRET + (_nDA_I_FRET - nVlrSomaFrete )
   EndIf
   If DAI->(FIELDPOS("DAI_I_VRPE")) > 0 .And. nVlrSomaPedag <> _nPedagio
      DAI->DAI_I_VRPE:= DAI->DAI_I_VRPE + (_nPedagio - nVlrSomaPedag )
   EndIf
   DAI->( MSUnLock() )
EndIf

Return .T.
/*
===============================================================================================================================
Programa----------: CalPesCarg
Autor-------------: Fabiano Dias
Data da Criacao---: 20/05/2010
Descrição---------: Funcao que soma o peso total da carga desconsiderando Produtos Unitizadores do Pallet
Parametros--------: _cCodigo	- Código da Carga/Pedido
------------------: _nTipo		- 1 = Peso Total da Carga / 2 = Peso Total do Pedido  / 3 = Peso Total do Pedido sem filtro
Retorno-----------: _nPesoTot	- Peso total calculado
===============================================================================================================================
*/
User Function CalPesCarg( _cCodigo As Char  , _nTipo As Numeric ) As Numeric

Local _oAliasPes:= GetNextAlias()
Local _cQuery	 := ""
Local _cGrpUnit := GetMV( "IT_GRPUNIT" ,, "0813" )
Local _nPesoTot := 0
Local _aArea	 := FwGetArea()

_cQuery += " SELECT SUM(PESOTOTAL) PESTOTAL FROM ( SELECT "
_cQuery += " Case WHEN  SC6.C6_I_PTBRU > 0  "
_cQuery += "      THEN  SC6.C6_I_PTBRU "
_cQuery += "      Else  COALESCE( ( SB1.B1_PESBRU * SC6.C6_QTDVEN ) , 0 )  END PESOTOTAL  "
_cQuery += " FROM " + RetSqlName("DAI") + " DAI "
_cQuery += " JOIN " + RetSqlName("SC6") + " SC6 ON DAI.DAI_PEDIDO = SC6.C6_NUM AND DAI.DAI_FILIAL = SC6.C6_FILIAL "
_cQuery += " JOIN " + RetSqlName("SB1") + " SB1 ON SC6.C6_PRODUTO = SB1.B1_COD "
_cQuery += " WHERE "
_cQuery += " 		DAI.D_E_L_E_T_	= ' ' "
_cQuery += " AND	SC6.D_E_L_E_T_	= ' ' "
_cQuery += " AND	SB1.D_E_L_E_T_	= ' ' "
If _nTipo <> 3
   _cQuery += " AND	SB1.B1_GRUPO	NOT IN "+ FormatIn( _cGrpUnit , ";" )  //EXCLUI GRUPOS UNITIZADORES
EndIf

If !Empty( xFilial("DAI") )
   _cQuery += " AND	DAI.DAI_FILIAL	= '" + xFilial("DAI") + "' "
EndIf

If !Empty(xFilial("SC6"))
   _cQuery += " AND	SC6.C6_FILIAL	= '" + xFilial("SC6") + "' "
EndIf

If !Empty(xFilial("SB1"))
   _cQuery += " AND	SB1.B1_FILIAL	= '" + xFilial("SB1") + "' "
EndIf

If _nTipo = 1//Efetua o somatorio do peso total da Carga
   _cQuery += " AND	DAI.DAI_COD = '"+ _cCodigo +"' "
ElseIf _nTipo = 2  .Or. _nTipo = 3//Efetua o somatorio do Peso do Pedido
   _cQuery += " AND	SC6.C6_NUM  = '" + _cCodigo + "'"
EndIf

_cQuery += " ) "//Fechamento DA SUB-QUERY

MPSysOpenQuery( _cQuery , _oAliasPes)

If (_oAliasPes)->(!Eof())
   _nPesoTot := (_oAliasPes)->PESTOTAL
EndIf

(_oAliasPes)->( DBCloseArea() )

FwRestArea( _aArea )

Return( _nPesoTot )
/*
===============================================================================================================================
Programa----------: VALIDAUT
Autor-------------: Guilherme Diogo
Data da Criacao---: 30/10/2012
Descrição---------: Funcao para validar codigo do autonomo informado
Parametros--------: _cAuto	- Código do Autônomo
Retorno-----------: _lRet	- Verdadeiro se o autônomo For encontrado / Falso se não existir no cadastro de Fornecedores
===============================================================================================================================
*/
Static Function VALIDAUT(_cAuto)

Local _cQrySA2	:= ""
Local _cAliasSA2:= GetNextAlias()
Local _lRet		:= .T.

//Query que verifica se codigo do autonomo informado existe na SA2
_cQrySA2 := " SELECT SA2.A2_COD FROM "+ RetSqlName("SA2") +" SA2 "
_cQrySA2 += " WHERE "
_cQrySA2 += " 		D_E_L_E_T_		= ' ' "
_cQrySA2 += " AND	(	A2_I_AUT	= '"+AllTrim(_cAuto)+"' "
_cQrySA2 += " 		OR	A2_I_AUTAV	= '"+AllTrim(_cAuto)+"' ) "

MPSysOpenQuery( _cQrySA2 , _cAliasSA2)

If (_cAliasSA2)->( Eof() )
   U_ITMsg('Código de Autônomo informado é inválido!'  ,;
            "Validação Campos",'Verificar o código informado!'	 ,1)
   _lRet := .F.
EndIf

(_cAliasSA2)->( DBCloseArea() )

Return(_lRet)

/*
===============================================================================================================================
Programa----------: VLDVLPAM
Autor-------------: Alexandre Villar
Data da Criacao---: 18/08/2014
Descrição---------: Funcao pra validar o valor Pamcary com relação ao valor do Frete
Parametros--------: Valores do Frete e Pamcary
Retorno-----------: _lRet - Verdadeiro se os valores informados estiverem consistentes
===============================================================================================================================
*/
Static Function VLDVLPAM( _nOpc , _nValor , _nVlrPam , _nPedagio )

Local _lRet	:= .T.

If ( _nOpc == 1 .And. _nVlrPam > 0 ) .Or. _nOpc == 2
   If _nValor > 0 .Or. _nVlrPam > 0
      _lRet := _nValor > _nVlrPam
      If !_lRet
            U_ITMsg('Valor do Pamcary invalido'  ,;
            "Validação Pamcary","O valor do Frete deve ser maior que o valor Pamcary!"	 ,1)
      EndIf
   EndIf
EndIf

If (_nOpc == 1 .Or. _nOpc == 3) .And. _nPedagio > 0
   If _nValor < _nPedagio
      U_ITMsg('Valor do Pedágio invalido'  ,;
            "Validação Frete","O valor do Frete deve ser maior/igual que o valor de Pedágio!"	 ,1)
      _lRet:=.F.
   EndIf
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: VLDVeiculo()
Autor-------------: Alex Wallauer
Data da Criacao---: 27/12/2016
Descrição---------: Funcao pra validar o Veiculo
Parametros--------: lOK: logico ,cCpo: origem
Retorno-----------: _lRet - Verdadeiro se os valores informados estiverem consistentes
===============================================================================================================================
*/
Static Function VLDVeiculo(lOK,cCpo)

If cCpo == "VEI" .Or. lOK
   DA3->(DBSetOrder(1))
   If Empty(_cCaminDAK)
      If _cPreCarga # "1"
            U_ITMsg('Código invalido'  ,"Validação Veiculo","Codigo do Veiculo não preenchido"	 ,1)
         Return .F.
      EndIf
   ElseIf !DA3->(DBSeek(xFilial()+_cCaminDAK))
      U_ITMsg('Código invalido'  ,"Validação Veiculo","Codigo: "+_cCaminDAK+" do Veiculo nao cadastrado"	 ,1)
      Return .F.

   ElseIf !lOK
      _cMotorDAK:=DA3->DA3_MOTORI
      DA4->(DBSetOrder(1))
      DA4->(DBSeek(xFilial("DA4")+_cMotorDAK))
      _cDDD := DA4->DA4_DDD
      _cCEL := DA4->DA4_TEL
   EndIf
EndIf

If cCpo == "MOTO" .Or. lOK
   DA4->(DBSetOrder(1))
   If Empty(_cMotorDAK)
      If _cPreCarga # "1"
         U_ITMsg('Código invalido'  ,"Validação Motorista","Codigo do Motorista não preenchido"	 ,1)
         Return .F.
      EndIf
   ElseIf !DA4->(DBSeek(xFilial()+_cMotorDAK))
      U_ITMsg('Código invalido'  ,"Validação motorista","Codigo: "+_cMotorDAK+" do motorista nao cadastrado"	 ,1)
      Return .F.
   Else
      If Upper(_cTipo) = "PJ-TRANSPORTADORA"
         If !Empty(DA4->DA4_FORNEC)
            SA1->(DBSetOrder(3))
            If SA2->( DBSeek( xFilial("SA2") + DA4->DA4_FORNEC+DA4->DA4_LOJA ) ) .And. SA1->( DBSeek( xFilial("SA1") + SA2->A2_CGC ) )
               If SA1->A1_MSBLQL == "1"

                  U_ITMsg("Cliente / CNPJ: "+SA1->A1_COD+" / "+SA1->A1_LOJA+" / "+SA2->A2_CGC+" esta Bloqueado no cadastro de Clientes."  ,;
                  "Validação Cliente",;
                  "Selecione um motorista com um Fornecedor / Cliente válido, caso precise gerar pedidos de Pallet de Retorno"	 ,1)

                  Return (!_lTemPalletRetorno)
               EndIf
            Else
               U_ITMsg("Cliente / CNPJ: "+SA1->A1_COD+" / "+SA1->A1_LOJA+" / "+SA2->A2_CGC+" não encontrados no cadastro de Clientes."  ,;
                  "Validação Cliente",;
                  "Selecione um motorista com um Fornecedor / Cliente válido, caso precise gerar pedidos de Pallet de Retorno"	 ,1)

                  Return (!_lTemPalletRetorno)
            EndIf
         Else
            U_ITMsg( "Fornecedor não preencchido no cadastro do motorista.","Validação Cliente",;
                                                "Selecione um motorista com um Fornecedor válido, caso precise gerar pedidos de Pallet de Retorno",1)
            Return (!_lTemPalletRetorno)
         EndIf
      EndIf

      If !lOK
         _cDDD := DA4->DA4_DDD
         _cCEL := DA4->DA4_TEL
      EndIf
   EndIf
EndIf

Return .T.
/*
===============================================================================================================================
Programa----------: VLDSA2
Autor-------------: Alex Wallauer
Data da Criacao---: 14/06/2016
Descrição---------: Funcao pra validar o Transportadora de redespacho e Operador Logistico
Parametros--------: _cCodSA2: chave ,cChamada: origem
Retorno-----------: _lRet - Verdadeiro se os valores informados estiverem consistentes
===============================================================================================================================
*/
Static Function VLDSA2(_cCodSA2,cChamada)
 Local lTemTRSim:=.F.
 Local lTemOLSim:=.F.
 Local lTemPal_0:=.F.,P,G
 Local aPVsCarga:={}
 Local aP2Vinculados:={}
 Local aPVdeGrupos  :={}

 SA2->(DBSetOrder(1))

 If cChamada # "OKTELA"

    If cChamada == "COLTR" .Or. cChamada == "COLOP"//ARRUMO A VARIAVEIS DA TELA PQ O F3 devolve codigo+loja na _cOpPed
       If Len(AllTrim(_cOpPed)) > Len(DAK->DAK_I_OPER)
          _cOpLja:=AllTrim(SubStr(_cOpPed, Len(DAK->DAK_I_OPER)+1, 4 ))
       EndIf
       _cOpPed:=LEFT(_cOpPed,Len(DAK->DAK_I_OPER))
    EndIf
    If cChamada == "TR" //ARRUMO A VARIAVEIS DA TELA PQ O F3 devolve codigo+loja na _cF3REDP
       If Len(AllTrim(_cF3REDP)) > Len(DAK->DAK_I_OPER)
          _cRELO:=AllTrim(SubStr(_cF3REDP, Len(DAK->DAK_I_OPER)+1, 4 ))
       EndIf
       _cF3REDP:=LEFT(_cF3REDP,Len(DAK->DAK_I_OPER))
       _cREDP  :=_cF3REDP//Atualiza pq usa em outros lugares
    EndIf
    If cChamada == "OL"//ARRUMO A VARIAVEIS DA TELA PQ O F3 devolve codigo+loja na _cF3OPER
       If Len(AllTrim(_cF3OPER)) > Len(DAK->DAK_I_OPER)
          _cOPLO:=AllTrim(SubStr(_cF3OPER, Len(DAK->DAK_I_OPER)+1, 4 ))
       EndIf
       _cF3OPER:=LEFT(_cF3OPER,Len(DAK->DAK_I_OPER))
       _cOPER  :=_cF3OPER//Atualiza pq usa em outros lugares
    EndIf

     If Empty(_cCodSA2)

         If cChamada == "TR"
             _cRELO := Space(Len(DAK->DAK_I_RELO))
         ElseIf cChamada == "OL"
             _cOPLO := Space(Len(DAK->DAK_I_OPLO))
         ElseIf cChamada == "COLTR" .Or. cChamada == "COLOL"
             U_ITMsg( "Código não preenchido","Atenção", "Para limpar código clique na coluna para mudar para 'Não'",1)
             Return .F.
         EndIf

     ElseIf SA2->(DBSeek(xFilial()+(_cCodSA2)))

         Z31->(DBSetOrder(1))
         If SA2->A2_I_CLASS # "T"  .Or. SA2->A2_MSBLQL # "2"

             U_ITMsg( "Código invalido","Validação Transportador",'Código: '+_cCodSA2+' não é do tipo Transportador ('+SA2->A2_I_CLASSL+') ou esta bloqueado ('+SA2->A2_MSBLQL+")",1)
             Return .F.

         //ElseIf !Z31->(DBSeek(xFilial()+AllTrim(_cCodSA2))) //Chamado 43489. desativado por enqunto

         //	U_ITMsg("Operador: "+_cCodSA2+" não tem Transit Time cadastrado (Z31).","ALERTA: Transit Time de Operadores Logisticos.",;
         //	        "Pode gravar a carga, mas na geração da nota não vai conseguir calcular o Transit Time do Operador.",2)

         EndIf

     Else
         U_ITMsg( "Código invalido","Validação Transportador", "Codigo: "+_cCodSA2+" do Transportador nao cadastrado",1)

         Return .F.

     EndIf

     If cChamada == "COLTR" .Or. cChamada == "COLOP"
        Return .T.
     EndIf

 EndIf

 DBSelectArea("TRBPED")
 DBGoTop()

 lTemduplo := .F.
 _cPedssemTT:=""
 _cOLssemTT:=""

 While !TRBPED->(Eof())

    If cChamada = "OKTR" .Or. cChamada = "OKTD"
       If TRBPED->PED_I_REDP = "1"
          lTemTRSim:=.T.
       EndIf

       If TRBPED->PED_I_REDP = "1" .And. TRBPED->PED_I_OPER  = "1"
          lTemduplo:=.T.
       EndIf

    ElseIf cChamada = "OKOL"
       If TRBPED->PED_I_OPER  = "1"
          lTemOLSim:=.T.
       EndIf

       If TRBPED->PED_I_REDP = "1" .And. TRBPED->PED_I_OPER  = "1"
          lTemduplo:=.T.
       EndIf

    ElseIf cChamada = "OKTELA"

       If TRBPED->PED_I_TIPC $ TP_GERA_PALET .And. Empty(TRBPED->PED_I_QTPA)
          lTemPal_0:=.T.
          Exit
       EndIf

       If SC5->( DBSeek( xFilial("SC5") + TRBPED->PED_PEDIDO ) )
          aAdd(aPVsCarga,SC5->C5_NUM)
          If !Empty(SC5->C5_I_PEVIN)
             aAdd(aP2Vinculados,{SC5->C5_NUM,SC5->C5_I_PEVIN})
          EndIf
          If SC5->(FIELDPOS("C5_I_AGRUP")) > 0  .And. !Empty(SC5->C5_I_AGRUP) .And. aScan(aPVdeGrupos,SC5->C5_I_AGRUP) = 0
             aAdd(aPVdeGrupos,SC5->C5_I_AGRUP)
          EndIf
       EndIf

 //	  cCodCli := SC5->C5_CLIENTE
 //    cLojaCli:= SC5->C5_LOJACLI
 //	  If !Empty(TRBPED->PED_I_OPLO)
 //	     cCodOL :=TRBPED->PED_I_OPLO
 //	     cLojaOP:=TRBPED->PED_I_LOPL
 //	  Else
 //	     cCodOL :=TRBPED->PED_I_TRED
 //	     cLojaOP:=TRBPED->PED_I_LTRE
 //	  EndIf

 //	  If !Empty(cCodOL) .And. !U_BuscaZ31(cCodOL,cLojaOP,cCodCli,cLojaCli) // Chamado 43489. desativado por enqunto
 //	     _cPedssemTT+="[ "+TRBPED->PED_PEDIDO+" ] "
 //		 If !cCodOL+"-"+cLojaOP $ _cOLssemTT
 //		    _cOLssemTT +="[ "+cCodOL+"-"+cLojaOP+" ] "
 //		 EndIf
 //	  EndIf

    ElseIf cChamada = "TR"

       If TRBPED->PED_I_REDP = "1" .And. TRBPED->PED_I_OPER  = "1"
          lTemduplo:=.T.
          Exit
       EndIf


    ElseIf cChamada = "OL"

       If TRBPED->PED_I_REDP = "1" .And. TRBPED->PED_I_OPER  = "1"
          lTemduplo:=.T.
          Exit
       EndIf

    EndIf

    TRBPED->(DBSkip())
 EndDo

 TRBPED->(DBGoTop())
 oMarkFim:oBrowse:Refresh()

 If cChamada = "OKTR"
    If !lTemTRSim .And. !Empty(_cCodSA2)
           U_ITMsg( "Nenhum Pedido com Redespacho","Atenção","Deve haver pelo menos 1 pedido marcado como SIM na coluna Redespacho",1)
          Return .F.
    EndIf
 EndIf

 If cChamada = "OKOL"
    If !lTemOLSim .And. !Empty(_cCodSA2)
       U_ITMsg( "Nenhum Pedido com Oper. Logistico","Atenção","Deve haver pelo menos 1 pedido marcado como SIM na coluna Oper. Logistico",1)
       Return .F.
    EndIf
 EndIf

 If cChamada == "OKTD"
    If lTemduplo
       U_ITMsg( "Pedido com Oper. Logistico e com Redespacho","Atenção","Não marcar um pedido como Redespacho e Operador logistico ao mesmo tempo",1)
         Return .F.
    EndIf
 EndIf

 If cChamada = "OKTELA"
    If lTemPal_0
       U_ITMsg( "Pedido: "+TRBPED->PED_PEDIDO+" paletizado com quantidade zerada","Atenção","Preencha a quantidade do Pallet do Pedido",1)
       Return .F.
    EndIf

    cFaltaPVinculado:=""
    cPVinculados:=""
    For P := 1 TO Len(aP2Vinculados)
        If aScan(aPVsCarga, aP2Vinculados[P,2]) = 0
           cFaltaPVinculado+=" PV "+aP2Vinculados[P,1]+" na carga sem o PV Vinculado "+aP2Vinculados[P,2]+CRLF
           cPVinculados+=aP2Vinculados[P,2]+", "
        EndIf
    Next

    If !Empty(cFaltaPVinculado)
       cPVinculados:=LEFT(cPVinculados,Len(cPVinculados)-2)
       U_ITMsg(cFaltaPVinculado,"Atenção","Retire o vinculo em alteração de Pedido ou adicione os PV vinculados faltantes na Carga: "+cPVinculados,1)
       Return .F.
    EndIf

    For P := 1 TO Len(aPVdeGrupos)

       _cQuery:=" SELECT C5_NUM FROM "+ RETSQLNAME("SC5") + " WHERE C5_FILIAL = '"+ xFilial('SC5')+"' AND D_E_L_E_T_ = ' ' "
       _cQuery+=" AND C5_I_AGRUP = '"+aPVdeGrupos[P]+"' "

       _cAliasGru:= GetNextAlias()
       MPSysOpenQuery( _cQuery , _cAliasGru)
       aPedidosGru:={}
       While (_cAliasGru)->(!Eof())
          aAdd(aPedidosGru,(_cAliasGru)->C5_NUM)
          (_cAliasGru)->(DBSkip())
       EndDo
       (_cAliasGru)->(DBCloseArea())

       cFaltadoGrupo:=""
       cPVdoGrupo   :=""

       For G := 1 TO Len(aPedidosGru)
           If aScan(aPVsCarga, aPedidosGru[G] ) = 0
              cFaltadoGrupo:=" Grupo "+aPVdeGrupos[P]+" de PVs na carga sem o(s) PV(s) do grupo: "
              cPVdoGrupo+=aPedidosGru[G]+", "
           EndIf
       Next

       If Len(cFaltadoGrupo) > 0
          cPVdoGrupo:=LEFT(cPVdoGrupo,Len(cPVdoGrupo)-2)
          U_ITMsg(cFaltadoGrupo+cPVdoGrupo,"Atenção","Adicione o(s) outro(s) pedido(s) do grupo: "+cPVdoGrupo,1)
            Return .F.
       EndIf

    Next

  // If !Empty(_cPedssemTT)//Chamado 43489. desativado por enqunto
  // 	  U_ITMsg("Esses Pedidos : "+_cPedssemTTLO+" possuem Operador Logistico sem transit time cadastrado.","ALERTA: Transit Time de Operadores Logisticos.",;
  //            "Pode gravar a carga, mas na geração da nota não vai conseguir calcular o Transit Time do(s) Operadore(s): "+_cOLssemTT,3)
  // EndIf

 EndIf

 TRBPED->(DBGoTop())
 oMarkFim:oBrowse:Refresh()

Return .T.

/*
===============================================================================================================================
Programa----------: OM200Marca
Autor-------------: Alex Wallauer
Data da Criacao---: 15/06/2016
Descrição---------: Funcao para troca sim e na dos campos de Transportadora de redespacho e Operador Logistico
Parametros--------: objBrowse: objeto ,lEfetiva_Pre_Carga: lógico
Retorno-----------: Verdadeiro
===============================================================================================================================
*/
Static Function OM200Marca(objBrowse,lEfetiva_Pre_Carga,aCpoBrw)
 Local _lOK    := .F.,_oDlg
 Local _nQtdeP := 0
 Local _bValid,_bValid2
 //Local _nCol1  :=7
 //Local _nCol2  :=9
 Local _nColA  :=7
 Local _nColB  :=_nColA+50
 Local _nTam   :=40
 Private _cOpPed := Space(Len(TRBPED->PED_I_TRED))//VariveL Private para o F3 customizado funcionar.
 Private _cOpLja := Space(Len(TRBPED->PED_I_LTRE))//VariveL Private para o F3 customizado funcionar.

 SC5->( DBSeek( xFilial("SC5") + TRBPED->PED_PEDIDO ) )//Posiciona por causa do F3 usa o estado do Pedido, NÃO RETIRE.

 //COLUNA DO FRETE 2o PERCURSO
 If _nColOLFOL > 0 .And. objBrowse:COLPOS = _nColOLFOL .And. (TRBPED->PED_I_OPER = "1" .Or.  TRBPED->PED_I_REDP = "1")
    _nGetValor:=TRBPED->PED_I_FROL
    If U_IT_EditCell(@_nGetValor,objBrowse,"@E 99,999.99",_nColOLFOL,"",.F.,{|| Positivo() },/*aComboBox*/)
       _nFretOL2-=TRBPED->PED_I_FROL
       If _nFretOL2 < 0
          _nFretOL2:=0
       EndIf
       TRBPED->PED_I_FROL:=_nGetValor
       _nFretOL2+=TRBPED->PED_I_FROL
       _oFret2:Refresh()
    EndIf
 EndIf

 //Coluna de sim/nao para redespacho
 If objBrowse:COLPOS = nColTR//2
    If TRBPED->PED_I_REDP # "1" .And. TRBPED->PED_I_OPER  # "1" .And. !Empty(_cREDP)//Só mexe na coluna se tiver o codigo preenchido e OL com não
       TRBPED->PED_I_REDP :=  "1"
       TRBPED->PED_I_TRED := _cREDP
       TRBPED->PED_I_LTRE := _cRELO
    Else
       TRBPED->PED_I_REDP := "2"
       TRBPED->PED_I_TRED := ""
       TRBPED->PED_I_LTRE := ""
       If TRBPED->PED_I_OPER  # "1" .And. TRBPED->(FIELDPOS("PED_I_FROL")) > 0
          _nFretOL2-=TRBPED->PED_I_FROL
          TRBPED->PED_I_FROL := 0
          If _nFretOL2 < 0
             _nFretOL2:=0
          EndIf
          _oFret2:Refresh()
       EndIf
    EndIf
 EndIf

 //Coluna de codigo de redespacho
 If objBrowse:COLPOS = _nColTRGet .And. TRBPED->PED_I_OPER  # "1" //Só mexe na coluna se tiver o OL com não //3

    _bValid := {|| VLDSA2(_cOpPed,"COLTR") }
    _bValid2:= {|| VLDSA2(_cOpPed+_cOpLja,"COLTR") }

    If !Empty(TRBPED->PED_I_TRED)

          _cOpPed :=	TRBPED->PED_I_TRED
          _cOpLja :=	TRBPED->PED_I_LTRE

    ElseIf !Empty(_cREDP) //Se transportador redespacho padrao estiver preenchido já preenche consulta

          _cOpPed :=	_cREDP
          _cOpLja :=	_cRELO

    EndIf

    DEFINE MSDIALOG _oDlg TITLE "Transp Redespacho para o pedido " + TRBPED->PED_PEDIDO FROM 000,000 TO 150,300 PIXEL

    @ 005, 007 Say "Transp Redespacho:" PIXEL
    @ 017, 009 MSGET _cOpPed SIZE 40,11 OF _oDlg F3 "F3ITLC" VALID ( EVAL(_bValid) ) PIXEL
    @ 017, 060 MSGET _cOpLja SIZE 30,11 OF _oDlg PIXEL

    @ 050,020	BMPBUTTON Type 01 ACTION Eval({|| If(EVAL(_bValid2),(_lok:=.T.,_oDlg:End()),)})
    @ 050,060	BMPBUTTON Type 02 ACTION Eval({|| _lok := .F. , _oDlg:End()} )

    Activate MSDialog _oDlg Centered

    If _lok

          TRBPED->PED_I_REDP  :=  "1"
          TRBPED->PED_I_TRED :=  _cOpPed
          TRBPED->PED_I_LTRE :=  _cOpLja

          If Empty(_cREDP) //Se transportador redespacho padrao estiver vazio já preenche

             _cREDP := _cOpPed
             _cRELO := _cOpLja
             _ocredp:Refresh()
             _ocrelo:Refresh()

          EndIf

    EndIf

 EndIf

 //Coluna de sim/nao para operador logistico
 If objBrowse:COLPOS = nColOL//5

       If TRBPED->PED_I_OPER  # "1" .And. TRBPED->PED_I_REDP # "1" .And. !Empty(_cOPER) //Só mexe na coluna se tiver o RD com não

          TRBPED->PED_I_OPER   :=  "1"
          TRBPED->PED_I_OPLO :=  _cOPER
          TRBPED->PED_I_LOPL :=  _cOPLO

       Else

          TRBPED->PED_I_OPER   :=  "2"
          TRBPED->PED_I_OPLO :=  ""
          TRBPED->PED_I_LOPL :=  ""
          If TRBPED->PED_I_REDP  # "1" .And. TRBPED->(FIELDPOS("PED_I_FROL")) > 0
             _nFretOL2-=TRBPED->PED_I_FROL
             TRBPED->PED_I_FROL := 0
             If _nFretOL2 < 0
                _nFretOL2:=0
             EndIf
             _oFret2:Refresh()
          EndIf

       EndIf

 EndIf

 //Coluna de codigo de operador logistico
 If objBrowse:COLPOS = _nColOLGet .And. TRBPED->PED_I_REDP # "1"//6

    _bValid := {|| VLDSA2(_cOpPed,"COLOP") }
    _bValid2:= {|| VLDSA2(_cOpPed+_cOpLja,"COLOP") }

    If !Empty(TRBPED->PED_I_OPLO) //Se transportador redespacho padrao estiver preenchido já preenche consulta

          _cOpPed :=	TRBPED->PED_I_OPLO
          _cOpLja :=	TRBPED->PED_I_LOPL

     ElseIf !Empty(_cOPER) //Se transportador redespacho padrao estiver preenchido já preenche consulta

          _cOpPed :=	_cOPER
          _cOpLja :=	_cOPLO

       EndIf

    DEFINE MSDIALOG _oDlg TITLE "Operador Logistico para o pedido " + TRBPED->PED_PEDIDO FROM 000,000 TO 150,300 PIXEL

    @ 005, 007 Say "Operador Logistico:" PIXEL
    @ 017, 009 MSGET _cOpPed SIZE 40,11 OF _oDlg F3 "F3ITLC" VALID ( EVAL(_bValid) ) PIXEL
    @ 017, 060 MSGET _cOpLja SIZE 30,11 OF _oDlg PIXEL

    @ 050,020  BMPBUTTON Type 01 ACTION Eval({|| If(EVAL(_bValid2),(_lok:=.T.,_oDlg:End()),) } )
    @ 050,060  BMPBUTTON Type 02 ACTION Eval({|| _lok := .F. , _oDlg:End()				} )

    Activate MSDialog _oDlg Centered

    If _lok

          TRBPED->PED_I_OPER   :=  "1"
          TRBPED->PED_I_OPLO :=  _cOpPed
          TRBPED->PED_I_LOPL :=  _cOpLja

          If Empty(_cOPER) //Se transportador redespacho padrao estiver vazio já preenche

             _cOPER := _cOpPed
             _cOPLO := _cOpLja
             _ooper:Refresh()
             _ooplo:Refresh()

          EndIf

    EndIf

 EndIf

 If lEfetiva_Pre_Carga// Só as colunas acimas podem ser alteradas
    Return .F.
 EndIf

 If objBrowse:COLPOS = nColTP//8
    _nQtdeP:= TRBPED->PED_I_QTPA
    _aTipoP:= { "1-Pallet Chep        ",;
                "2-Estivada           ",;
                "3-Pallet PBR         ",;
                "4-Pallet Descartavel ",;
                "5-Pallet Chep Retorno",;
                "6-Pallet PBR Retorno "}
    _cTipoP:= _aTipoP[Val(TRBPED->PED_I_TIPC)]
    _lOK   := .F.

    _bValid:= {|| If(!LEFT(_cTipoP,1) $ TP_GERA_PALET .Or. Positivo(_nQtdeP),_lOK:=.T.,.F.) }
    _nLinP := 05
    nAltura:=200

    DEFINE MSDIALOG _oDlg TITLE "Dados do Pallet" FROM 000,000 TO nAltura,260 PIXEL

    @ _nLinP+10, _nColA Say "Tipo de Carga?" PIXEL
    @ _nLinP, _nColB MSCOMBOBOX	_cTipoP	SIZE 070,045 ITEMS _aTipoP OF _oDlg PIXEL
      _nLinP+=25
    @ _nLinP+10, _nColA Say "Quantidade Pallet?" PIXEL
    @ _nLinP, _nColB MSGET _nQtdeP Picture "@E 999,999" SIZE _nTam,11 OF _oDlg VALID ( EVAL(_bValid) ) PIXEL WHEN If(LEFT(_cTipoP,1) $ TP_GERA_PALET,.T.,(_nQtdeP:=0,.F.))
      _nLinP+=25
    @ _nLinP,020 BMPBUTTON Type 01 ACTION If(EVAL(_bValid),(_lOK:=.T.,_oDlg:End()),)
    @ _nLinP,060 BMPBUTTON Type 02 ACTION Eval({|| _lOK := .F.       ,_oDlg:End()} )

    Activate MSDialog _oDlg Centered

    If _lOK
       TRBPED->PED_I_TIPC := _cTipoP
       TRBPED->PED_I_QTPA := _nQtdeP
    EndIf

 EndIf

 If objBrowse:COLPOS = nColQT .And. TRBPED->PED_I_TIPC $ TP_GERA_PALET//9

    _nQtdeP:= TRBPED->PED_I_QTPA
    If U_IT_EditCell(@_nQtdeP,objBrowse,X3Picture("DAI_I_QTPA"),nColQT,"",.F.,{|| Positivo() },/*aComboBox*/)
       TRBPED->PED_I_QTPA := _nQtdeP
    EndIf
    
    // Mantive caso os usarios queiram voltar a usar o dialogo de paletizacao
    //_lOK   := .F.
    //_bValid:= {|| If(Positivo(_nQtdeP),(_lOK:=.T.,_oDlg:End()),.F.) }
    //DEFINE MSDIALOG _oDlg TITLE "Pallets" FROM 000,000 TO 080,120 PIXEL
    //@ 005, _nCol1 Say "Quantidade Pallet:" PIXEL
    //@ 014, _nCol2 MSGET _nQtdeP Picture "@E 999,999" SIZE _nTam,11 OF _oDlg VALID ( EVAL(_bValid) ) PIXEL
    //@ 100,0110	BMPBUTTON Type 01 ACTION EVAL(_bValid)
    //Activate MSDialog _oDlg Centered
    //If _lOK
    //   TRBPED->PED_I_QTPA := _nQtdeP
    //EndIf

 EndIf

Return .T.
/*
===============================================================================================================================
Programa--------: U_OM200Email
Autor-----------: Alex Walallauer
Data da Criacao-: 22/06/2065
Descrição-------: Monta e dispara o WF de comunicação da Montagem de Carga
Parametros------: _lEstorno.....: Se .T. foi chamdo do estorno
                  _aCarga.......: Lista de Pedidos da Carga
                  _cObsEmail....: Observacao no Corpo do Email
                  _lEnviaDireto.: Envia o e-mail direto sem perguntar
                  _lScheduller..: Sem tela
                  _lMarcaEnvio..: Marca o envio para o RDC
Retorno---------: .T.
===============================================================================================================================*/
//***************************************************************************// CUIDADO TESTAR A CHAMADA DE TODOS OS LUGARES
User Function OM200Email(_lEstorno,_aCargas,_lEnviaDireto,_lScheduller,_lMarcaEnvio,_cCodUser)
                                                          //1-Chamada das Acoes Relacionadas Reenvio WF da montagem da carga,
                                                          //2-No Estorno da Carga
                                                          //3-Na funcao MT103FIM()
 //***************************************************************************//
 Local _cEmail	 := ""
 Local _cObsEmail := ""// Para variavel usada em GET MEMO nao precisa inicia com Space()
 Local oproc

 Private _lAutomatico

 DEFAULT _lEstorno      := .F.
 DEFAULT _aCargas       := {}
 DEFAULT _lEnviaDireto  :=.T.
 DEFAULT _lMarcaEnvio   :=.T.
 DEFAULT _cCodUser      := ""

 If Empty(_lScheduller)
    _lAutomatico := .F.
 Else
    _lAutomatico := _lScheduller
 EndIf

 _cEmail:=BuscaEmail(_lAutomatico,"")//Só para verificar se tem algum emal para enviar

 If Empty( _cEmail )
    If !_lEstorno .And. Len(_aLog) = 0
       If ! _lAutomatico
          U_ITMsg( "Sem e-mail cadastrado!","Atenção",'Verifique o parametro "IT_WFCARGA" com a área de TI / ERP.',1)
       EndIf
    EndIf
    Return .F.
 EndIf

 If ! _lAutomatico
    If _lEnviaDireto .And. !OM200PegaObs(@_cObsEmail)
       Return .F.
    EndIf

    FWMsgRun( ,{|oproc| OM200Email(_lEstorno,_aCargas,_cObsEmail,_lEnviaDireto,_lMarcaEnvio,oproc,_cCodUser) } ,'Aguarde!' ,'Enviando WF ...'    )
 Else
    OM200Email(_lEstorno,_aCargas,_cObsEmail,_lEnviaDireto,_lMarcaEnvio,,_cCodUser)
 EndIf

Return .T.
/*
===============================================================================================================================
Programa--------: OM200Email
Autor-----------: Alex Walallauer
Data da Criacao-: 22/06/2065
Descrição-------: Monta e dispara o WF de comunicação da Montagem de Carga
Parametros------: _lEstorno.....: Se .T. foi chamdo do estorno
                  _aCarga.......: Lista de Pedidos da Carga
                  _cObsEmail....: Observacao no Corpo do Email
                  _lEnviaDireto.: Envia o e-mail direto sem perguntar
                  _lMarcaEnvio..: Marca o envio para o RDC
                  _oproc........: objeto da barra de processamento
Retorno---------:.T.
===============================================================================================================================*/
//***************************************************************************// CUIDADO TESTAR A CHAMADA DE TODOS OS LUGARES
Static Function OM200Email(_lEstorno,_aCargas,_cObsEmail,_lEnviaDireto,_lMarcaEnvio, oproc, _cCodUser)//1-Chamada da funcao acima e
                                                                       //2-Na gravacao da Carga acima
 //***************************************************************************//
 Local _aConfig	  := U_ITCFGEML('')
 Local _cEmail	  := ""
 Local _cMsgEml	  := ''
 Local _cAssunto   := ''
 Local _cData      := DToC( Date() )
 Local _cNomeFilial:= ""
 Local _lGerouPDF  := .T.//Inicia com .T. pq o Estorno enviar e-mail sem Anexo
 Local _cTextoObs  := "",_nI
 Local _cMailUser  := ""
 Local _ntot := 0
 Local _npos := 1
 Local _cEnvPor, _cCodEnvPor, _cEmailEnvPor

 DEFAULT _lEnviaDireto:=.F.
 DEFAULT _lMarcaEnvio :=.T.//Essa funcao Static OM200Email() tb é chamada direto desse ponto de entrada
 Default oproc := nil

 If _lAutomatico .And. _lMarcaEnvio .And. ZFU->(FIELDPOS("ZFU_ENMAIL")) # 0
    //U_ITCONOUT("Marcou envio do E-MAIL da Carga: "+DAK->DAK_COD) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
    _lEnviaEmail := .T.
    Return .T.
 EndIf

 _cEmail:=BuscaEmail(_lAutomatico,@_cMailUser)//Aqui busca mesmo todos os emails

If !Empty(_cCodUser)
   _cEnvPor := UsrFullName(_cCodUser)
Else
   _cEnvPor := UsrFullName(__cUserId)
EndIf

 If Empty( _cEmail )
   If ! _lAutomatico
      If !_lEstorno
         U_ITMsg("Sem e-mail cadastrado","Atenção",Upper('Dados gravado com sucesso.'), 1 )
      EndIf
   //Else
      //U_ITCONOUT("Sem e-mail cadastrado para filial: "+xFilial("ZP1")+" - IT_WFCARGA") // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
   EndIf
 Else
   If ! _lAutomatico
      ProcRegua(0)
   Else
      _lEnviaDireto := .T.
   EndIf

    If !_lEstorno .And. (_cObsEmail = NIL .Or. Empty(_cObsEmail))
       _cTextoObs := AllTrim(DAK->DAK_I_OBS) + " " + AllTrim(DAK->DAK_I_OBS2)
       _cTextoObs := Upper(_cTextoObs)
       _cObsEmail := AllTrim(StrTran(_cTextoObs,Char(13)+Char(10)," "))
    Else
       _cObsEmail:=AllTrim(StrTran(_cObsEmail,Char(13)+Char(10)," "))
    EndIf

    If _aCargas = NIL .Or. Empty(_aCargas)
       _aCargas:=U_OM200_Carrega()
    EndIf

    If _lEstorno
       _cCarga  := _cCargas//Vairavel Private do rdmake OM200MNU.PRW
       _cNomeFilial:= xFilial("DAK")+" - "+AllTrim( Posicione('SM0',1,cEmpAnt+xFilial("DAK"),'M0_FILIAL') )
       _cAssunto   := "ESTORNO de Carga: "+_cCarga+" / Filial: "+ _cNomeFilial +' - Notificação ['+ DToC( Date() ) +']'
    Else
       _cCarga  := DAK->DAK_COD
       _cData   := DToC( DAK->DAK_DATA)
       _cNomeFilial:= DAK->DAK_FILIAL+" - "+AllTrim( Posicione('SM0',1,cEmpAnt+DAK->DAK_FILIAL,'M0_FILIAL') )
       If DAK->DAK_I_PREC = "1"
          _cAssunto   :="MONTAGEM de PRE-Carga: "+_cCarga+" / Filial: "+ _cNomeFilial +' - Notificação ['+ DToC( Date() ) +']'
       Else
          _cAssunto   :="MONTAGEM de Carga: "+_cCarga+" / Filial: "+ _cNomeFilial +' - Notificação ['+ DToC( Date() ) +']'
       EndIf
    EndIf

    If _lAutomatico
       If Empty(_cEnvPor)
          //=====================================================================================
          // Pega nome do usuÃ¡rio
          //=====================================================================================
          _cCodEnvPor := SubStr(Embaralha(DAK->DAK_USERGI,1),3,6) //Embaralha(DAK->DAK_USERGA, 1)
          _cEnvPor := UsrFullName(_cCodEnvPor)

          _cEmailEnvPor :=FWSFAllUsers({_cCodEnvPor},{"USR_EMAIL"})[1][3]

          If !Empty(_cEmailEnvPor)
             _cEmail := AllTrim(_cEmail) + "; "+_cEmailEnvPor
          EndIf

       EndIf
    EndIf

    _cMsgEml := '<html>'
    _cMsgEml += '<head><title>Montagem de Carga</title></head>'
    _cMsgEml += '<body>'
    _cMsgEml += '<style Type="text/css"><!--'
    _cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
    _cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
    _cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
    _cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
    _cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
    _cMsgEml += '--></style>'
    _cMsgEml += '<center>'
    _cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
    _cMsgEml += '<table class="bordasimples" width="600">'
    _cMsgEml += '    <tr>'
    _cMsgEml += '	     <td class="titulos"><center>'+_cAssunto+'</center></td>'
    _cMsgEml += '	 </tr>'
    _cMsgEml += '</table>'
    _cMsgEml += '<br>'
    _cMsgEml += '<table class="bordasimples" width="600">'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td align="center" colspan="2" class="grupos">Carga: <b>'+ _cCarga +'</b></td>'
    _cMsgEml += '    </tr>'

    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Enviado por: </b></td>'
    _cMsgEml += '      <td class="itens" >'+ _cEnvPor +'</td>' // UsrFullName(__cUserId)
    _cMsgEml += '    </tr>'

    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial:</b></td>'
    _cMsgEml += '      <td class="itens" >'+ _cNomeFilial +'</td>'
    _cMsgEml += '    </tr>'

    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Data Carga:</b></td>'
    _cMsgEml += '      <td class="itens" >'+ _cData +'</td>'
    _cMsgEml += '    </tr>'

    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Observações:</b></td>'
    _cMsgEml += '      <td class="itens" >#OBS#</td>'
    _cMsgEml += '    </tr>'

    _cMsgEml += '	<tr>'
    _cMsgEml += '		<td class="grupos" align="center" colspan="2"><b>Para maiores informações acesse o arquivo anexo.</b></td>'
    _cMsgEml += '	</tr>'
    _cMsgEml += '	<tr>'
    _cMsgEml += '      <td class="titulos" align="center" colspan="2"><font color="red"><u>Esta é uma mensagem automática. Por favor não a responda!</u></font></td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '</table>'

    If !Empty(_aCargas)
       If ! _lAutomatico
          _ntot := Len(_aCargas)+2
       EndIf

        _cMsgEml += '<br>'
        _cMsgEml += '<table class="bordasimples" width="800">'
        _cMsgEml += '    <tr>'
        _cMsgEml += '      <td align="center" colspan="4" class="grupos">Pedidos da Carga</b></td>'
        _cMsgEml += '    </tr>'
        _cMsgEml += '    <tr>'
        _cMsgEml += '      <td class="itens" align="center" width="12%"><b>Pedido</b></td>'
        _cMsgEml += '      <td class="itens" align="center" width="54%"><b>Local de Entrega</b></td>'
        _cMsgEml += '      <td class="itens" align="center" width="19%"><b>Peso</b></td>'
        _cMsgEml += '      <td class="itens" align="center" width="15%"><b>Tipo Carga</b></td>'
        _cMsgEml += '    </tr>'


        SC5->( DBSetOrder(1) )
        SA3->(DBSetOrder(1))

        For _nI := 1 To Len( _aCargas )
            If ! _lAutomatico

              If ValType(oproc) = "O"

                      oproc:cCaption := ("Lendo Pedido: "+_aCargas[_nI][01] + " - " + StrZero(_npos,6) + " de " + StrZero(_ntot,6))
                      _npos++
                      ProcessMessages()

              EndIf

            EndIf

            _cMsgEml += '    <tr>'
            _cMsgEml += '      <td class="itens" align="center" width="12%">'+ _aCargas[_nI][01] 	+'</td>'
            _cMsgEml += '      <td class="itens" align="left"   width="54%">'+ _aCargas[_nI][05] +'</td>'
            _cMsgEml += '      <td class="itens" align="right"  width="19%">'+ Transform( _aCargas[_nI][02] , "@E 9,999,999,999."+Replicate("9",TamSX3("DAK_PESO")[2]) )+' KG </td>'
            _cMsgEml += '      <td class="itens" align="center" width="15%">'+ _aCargas[_nI][06]+'</td>'
            _cMsgEml += '    </tr>'

        Next

        _cMsgEml += '</table>'

    EndIf

    _cMsgEml += '</center>'
    _cMsgEml += '<br>'
    _cMsgEml += '<br>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
    _cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [OM200FIM]</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '</body>'
    _cMsgEml += '</html>'
    _cEmlLog := ''

    // ENVIO DO EMAIL COM ANEXO Ex.: \SPOOL\Roms004_20160714_085326.pdf
    If ! _lAutomatico

       If ValType(oproc) = "O"

            oproc:cCaption := ("WF para: "+_cEmail)
               ProcessMessages()

       EndIf

    EndIf

    //Variaveis Private usadas na funcao: ROMS004  \/\/\/\/\/
    MV_PAR01:=DAK->DAK_COD
    MV_PAR02:=DAK->DAK_COD
    MV_PAR03:= 3
    _cFileName:=""//O nome é preenchido na funcao ROMS004(.T.) - Ex.: %TEMP%\CARGA_MV_PAR01_20160714_085326.pdf
    //Variaveis Private usadas na funcao: ROMS004 /\/\/\/\/\

    If !_lAutomatico .And. !_lEstorno

        _lGerouPDF := U_ROMS004(.T., .T.) //Roda automático e mostra o relatório
        If !_lGerouPDF
           _lEnvioOK:=.F.//USADO NO PROGRAMA AOMS101.PRW
        EndIf

    ElseIf !_lEstorno

         //U_ITCONOUT("Tentando Gerar PDF para enviar por e-mail") // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
        _lGerouPDF := U_ROMS004(.T., .F.) //Roda automatico sem mostrar o relatório
        _ntamanho := 0
        _adatfile := {}
        _nI := 0

        //Verifica se gerou pdf com tamanho maior que zero, em caso de erro repete o relatório até três vezes
        While _nI <= 3 .And. _ntamanho = 0

             _ntamanho := 0
             _adatfile := {}
             If file(_cfilename)
                  _adatfile := directory(_cfilename)
                  _ntamanho := _adatfile[1][2]
             EndIf
             If _ntamanho = 0
                U_MostraCalls()
                //U_ITCONOUT("Tentariva "+cvaltochar(_nI)+" Anexo: " + AllTrim(_cfileName) + " de tamanho: " + AllTrim(transform(_ntamanho,"@E 9,999,999"))) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
                 ferase(_cfilename)
                 _lGerouPDF := U_ROMS004(.T., .F.) //Roda automatico sem mostrar o relatório
             EndIf
             _nI++

        EndDo
        If !_lGerouPDF
           _lEnvioOK:=.F.//USADO NO PROGRAMA AOMS101.PRW
        EndIf

    EndIf

    If _lEnviaDireto .Or. OM200PegaObs(@_cObsEmail)

       If ! _lAutomatico
          If ValType(oproc) = "O"
             oproc:cCaption := ("Enviado para: "+_cEmail)
             ProcessMessages()
          EndIf
       EndIf

       _cMsgEml:=StrTran(_cMsgEml,"#OBS#",_cObsEmail)
       If _lGerouPDF    //Quando é estorno envia o e-mail sem anexo mesmo
        //U_ITENVMAIL(cFrom         ,cEmailTo ,cEmailCo  ,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
          U_ITENVMAIL( _aConfig[01] , _cEmail ,_cMailUser,         ,_cAssunto, _cMsgEml,_cFileName,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
          If !"SUCESSO" $ Upper(_cEmlLog)// SE NÃO ENVIO O EMAIL NÃO MARCA NO
             _lEnvioOK:=.F.//USADO NO PROGRAMA AOMS101.PRW
          EndIf
       EndIf

       If !_lEstorno
          _ntamanho := 0
          _adatfile := {}

          If file(_cfilename)
             _adatfile := DIRECTORY(_cfilename)
             _ntamanho := _adatfile[1][2]
          Else
             _cfilename:= "Arquivo ("+_cfilename+") nao localizado no envio do email"
             _ntamanho := 0
          EndIf
          //U_ITCONOUT("Anexo: " + AllTrim(_cfileName) + " de tamanho: " + AllTrim(transform(_ntamanho,"@E 9,999,999"))) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
          If _ntamanho <= 0
              U_MostraCalls()
          EndIf

          If !_lGerouPDF
             _cEmlLog+=" (NÃO ENVIO O E-mail para: "+_cEmail+") (Com Copia: "+_cMailUser+") - Com anexo " + AllTrim(_cfileName) + " de tamanho " + transform(_ntamanho,"@E 9,999,999")
          ElseIf _lAutomatico
             _cEmlLog+=" (E-mail para: "+_cEmail+") (Com Copia: "+_cMailUser+") - Com anexo " + AllTrim(_cfileName) + " de tamanho " + transform(_ntamanho,"@E 9,999,999")
          EndIf
       EndIf

       If !Empty( _cEmlLog ) //.AND. !_lEstorno
          If !_lAutomatico
             If !_lEstorno
                   Aviso(Upper('Dados gravado com sucesso. (OM200FIM)'),Upper(_cEmlLog)+CHR(13)+CHR(10)+;
                   CHR(13)+CHR(10)+" E-mail para: "+_cEmail +" - Com anexo " + AllTrim(_cfileName) + " de tamanho " + transform(_ntamanho,"@E 9,999,999") +CHR(13)+CHR(10)+;
                   CHR(13)+CHR(10)+" Com Copia: "+_cMailUser+CHR(13)+CHR(10)+;
                   If(_cFileName # nil,CHR(13)+CHR(10)+" Anexo: "+_cFileName,""),{"OK"} , 3 )
             Else
                   Aviso(Upper('Dados gravado com sucesso. (OM200FIM)'),Upper(_cEmlLog)+CHR(13)+CHR(10)+;
                     CHR(13)+CHR(10)+" E-mail para: "+_cEmail +CHR(13)+CHR(10)+;
                     CHR(13)+CHR(10)+" Com Copia: "+_cMailUser+CHR(13)+CHR(10),{"OK"} , 3 )
             EndIf
          //Else
             //U_ITCONOUT("_cEmlLog: "+_cEmlLog) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
             //U_ITCONOUT("E-mail para: " + _cEmail +" Com Copia: "+_cMailUser) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
             //U_ITCONOUT("Fim do envio do E-MAIL: "+_cAssunto) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
          EndIf
       EndIf

    EndIf

    If _cFileName # nil .And. !Empty(_cFileName) .And. FILE(_cFileName)
       If FErase(_cFileName) = 0
          //U_ITCONOUT("Arquivo "+_cFileName+" apagado com sucesso") // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
       EndIf
    EndIf

    If _cFileName # nil .And. !Empty(_cFileName)
       _cFileRelName:=StrTran( Upper(_cFileName), ".PDF", ".REL")
       If FILE(_cFileRelName)
          If FErase(_cFileRelName) = 0
             //U_ITCONOUT("Arquivo "+_cFileRelName+" apagado com sucesso") // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
          EndIf
       EndIf
    EndIf

 EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: U_OM200_Carrega()
Autor-------------: Alex Wallauer
Data da Criacao---: 26/07/2016
Descrição---------: Leitura dos dados da Carga
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: _aCargas: array de pedidos
===============================================================================================================================*/
User Function OM200_Carrega(oproc)
 Local _aCargas:={}
 Local _cNomCli:=''
 Default oproc := nil

 SC5->( DBSetOrder(1) )
 DAI->( DBSetOrder(1) )

 If DAI->( DBSeek( xFilial("DAI") + DAK->DAK_COD ) )


    While DAI->( !Eof() ) .And. DAI->( DAI_FILIAL + DAI_COD ) == xFilial("DAI") + DAK->DAK_COD
       If ! _lAutomatico

         If ValType(oproc) = "O"

                  oproc:cCaption := ("Lendo Pedido: "+DAI->DAI_PEDIDO)
                  _npos++
                  ProcessMessages()

         EndIf

       EndIf

        If !SC5->( DBSeek( xFilial("SC5") + DAI->DAI_PEDIDO ) )
            DAI->(DBSkip())
            Loop
        EndIf
        _cNomCli:=''

        If SC5->C5_TIPO $ "B/D"

            SA2->( DBSetOrder(1) )
            If SA2->( DBSeek( xFilial("SA2") + DAI->( DAI_CLIENT + DAI_LOJA ) ) )
                _cNomCli := "FO: "+DAI->DAI_CLIENT+" - "+AllTrim(SA2->A2_NOME)
            EndIf

        Else

            SA1->( DBSetOrder(1) )
            If SA1->( DBSeek( xFilial("SA1") + DAI->( DAI_CLIENT + DAI_LOJA ) ) )
                _cNomCli := "CL: "+DAI->DAI_CLIENT+" - "+AllTrim(SA1->A1_NOME)
            EndIf

        EndIf

        If !Empty(DAI->DAI_I_OPLO)

            _coplog := DAI->DAI_I_OPLO
            _coploj := DAI->DAI_I_LOPL

        Else

            _coplog := DAK->DAK_I_OPER
            _coploj := DAK->DAK_I_OPLO

        EndIf

        If !Empty(DAI->DAI_I_TRED)

            _ctred := DAI->DAI_I_TRED
            _ctrlj := DAI->DAI_I_LTRE

        Else

            _ctred := DAK->DAK_I_REDP
            _ctrlj := DAK->DAK_I_RELO

        EndIf


        If DAI->DAI_I_OPER="1" .And. !Empty(_coplog) .And. SA2->( DBSeek( xFilial('SA2') + _coplog+_coploj ) )
            _cNomCli := "OP: "+_coplog+" - "+AllTrim(SA2->A2_NOME)
        EndIf

        If DAI->DAI_I_REDP="1" .And. !Empty(_ctred) .And. SA2->( DBSeek( xFilial('SA2') + _ctred+_ctrlj ) )
            _cNomCli := "TR: "+_ctred+" - "+AllTrim(SA2->A2_NOME)
        EndIf

        _cTipoCarga:=If(DAI->DAI_I_TIPC="1","Pallet Chep",;
                     If(DAI->DAI_I_TIPC="2","Estivada",;
                     If(DAI->DAI_I_TIPC="3","Pallet PBR",;
                     If(DAI->DAI_I_TIPC="4","Plt Descartavel",;
                     If(DAI->DAI_I_TIPC="5","Plt Chep Retorno",;
                     If(DAI->DAI_I_TIPC="6","Plt PBR Retorno","            "))))))

        aAdd(_aCargas,{DAI->DAI_PEDIDO,;//01
                       DAI->DAI_PESO,;  //02
                       DAI->(RECNO()),; //03 - Usado no Estono da Carga
                       ""            ,; //04
                       _cNomCli,;       //05
                       _cTipoCarga })   //06

        DAI->(DBSkip())

    EndDo

 EndIf

Return _aCargas

/*
===============================================================================================================================
Programa----------: AcessaPV()
Autor-------------: Josué Danich
Data da Criacao---: 14/11/2016
Descrição---------: Visualiza Pedido
Parametros--------: cpedido - Numero do pedido
Retorno-----------: Nenhum
===============================================================================================================================*/
User Function IT_VisuPV(cPedido As Char)
 Local aArea       := FwGetArea() As Array //Irei gravar a area atual
 Private Inclui    := .F. As Logical //defino que a inclusão é falsa
 Private Altera    := .T. As Logical //defino que a alteração é verdadeira
 Private nOpca     := 1   As Numeric //obrigatoriamente passo a variavel nOpca com o conteudo 1
 Private cCadastro := "Pedido de Vendas" As Char //obrigatoriamente preciso definir com Private a variável cCadastro
 Private aRotina   := {} As Array //obrigatoriamente preciso definir a variavel aRotina como private

 DBSelectArea("SC5") //Abro a tabela SC5
 SC5->(DBSetOrder(1)) //Ordeno no índice 1
 SC5->(DBSeek(xFilial("SC5")+cPedido)) //Localizo o meu pedido
 If SC5->(!Eof()) //Se o pedido existe irei continuar
    SC5->(DBGoTo(Recno())) //Me posiciono no pedido
    FWMsgRun( ,{|| MatA410(Nil, Nil, Nil, Nil, "A410Visual")},'Aguarde!','Lendo dados do Pedido...')
 EndIf
 SC5->(DBCloseArea()) //quando eu sair da tela de visualizar pedido, fecho o meu alias
 FwRestArea(aArea) //restauro a area anterior.

Return
/*
===============================================================================================================================
Programa----------: OM200Pallets()
Autor-------------: Alex Wallauer
Data da Criacao---: 17/08/2016
Descrição---------: Leitura dos dados dos Pallets
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================*/
Static Function OM200Pallets()
 Local _cQuery1:=" SELECT SUM(C6_I_QPALT) NQTD FROM "+ RETSQLNAME("SC6") + " WHERE C6_FILIAL = '"+ xFilial('SC6')+"' AND D_E_L_E_T_ = ' ' "
 Local _cQuery2:="",_cPallet,_TipoC
 Local _cAlias:=GetNextAlias()

_nFretOL2:=0//variavel Statica

 SA2->( DBSetOrder(1) )
 SA1->( DBSetOrder(1) )
 SC5->( DBSetOrder(1) )
 _cEstados:=""//Variavel preenchida para o F3 dos operadores, NÃO RETIRE
 TRBPED->(DBGoTop())
 While TRBPED->(!Eof())//o TRBPED já está filtrado só os pedidos marcados

    SC5->( DBSeek( xFilial("SC5") + TRBPED->PED_PEDIDO ) )
    If !Empty(SC5->C5_I_EST) .And. !SC5->C5_I_EST $ _cEstados
       _cEstados+=SC5->C5_I_EST+";"//Variavel preenchida para o F3 dos operadores, NÃO RETIRE
    EndIf

    If Empty(TRBPED->PED_I_TIPC)//Esse controle é pela primeira fez que entra na tela e o campo SC5->C5_I_TIPCA estava em branco

       _cPallet:="2"
       _TipoC  :=""

       If SA1->( DBSeek( xFilial("SA1") + TRBPED->(PED_CODCLI+PED_LOJA) ) )
          _TipoC := SA1->A1_I_CHEP
            If !Empty(SA1->A1_I_PALET)
             _cPallet:= SA1->A1_I_PALET
             EndIf
       EndIf


       If Empty(_TipoC)
          _TipoC := "C"
       EndIf

       TRBPED->PED_I_TIPC:= "2"

       If !SC5->C5_TIPO $ "B/D"//Se NÃO For beneficiamento e Devolução
          If _cPallet $ "S,1"
             If _TipoC = "C"//Esse controle é pela a origem dos dados para deixar alterar o tipo de carga inclusive se o usuario já alterou, saiu e entrou na tela de novo
                TRBPED->PED_I_TIPC:= "1"
             Else
                TRBPED->PED_I_TIPC:= "3"
             EndIf
          Else
             TRBPED->PED_I_TIPC:= "2"
          EndIf
       EndIf

    EndIf

    If TRBPED->PED_I_TIPC $ "5,6"//"5-Pallet Chep Retorno","6-Pallet PBR Retorno"
       _lTemPalletRetorno:=.T.
    EndIf

    If TRBPED->PED_I_TIPC $ TP_GERA_PALET .And. Empty(TRBPED->PED_I_QTPA)//Esse controle é para nao sobrepor os dados que o usuario já alterou, saiu e entrou na tela de novo

       _cQuery2:=" AND C6_NUM = '"+ TRBPED->PED_PEDIDO+"' "

       MPSysOpenQuery( (_cQuery1+_cQuery2) , _cAlias)

       If (_cAlias)->( !Eof() )
           TRBPED->PED_I_QTPA := Round((_cAlias)->NQTD,0)
       EndIf

       (_cAlias)->( DBCloseArea() )

    EndIf

    If TRBPED->(FIELDPOS("PED_I_FROL")) > 0
       _nFretOL2+=TRBPED->PED_I_FROL
    EndIf

    TRBPED->(DBSkip())

 EndDo

 DBSelectArea("TRBPED")

Return .T.

/*
===============================================================================================================================
Programa--------: GeraPedPallet(_aPeds_Pallet,_lAutomatico)
Autor-----------: Alex Wallauer
Data da Criacao-: 18/08/2016
Descrição-------: Gera Pedidos de Pallet
Parametros------: Lista de dos pedidos
                  _lAutomatico = .T. = Rotina rodada automaticamente / .F. = Rotina rodada manualmente. / oproc barra de processamento
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================
*/
Static Function GeraPedPallet(_aPeds_Pallet,_lAutomatico,oproc)
 Local _cDesc  := "",_cPedPallet
 Local _nPreco := _nTotVlrPal:=_nPallet:=0
 Local _cUM	  := "",_Ped
 Local _ntot := 0
 Local _npos := 1
 Local _citls := AllTrim(SuperGetMV('IT_CHEPITS',.T.,''))
 Local _citln := AllTrim(SuperGetMV('IT_CHEPITN',.T.,''))
 Local _cclis := AllTrim(SuperGetMV('IT_CHEPCLS',.T.,''))
 Local _cclin := AllTrim(SuperGetMV('IT_CHEPCLN',.T.,''))
 Local _cchep := SuperGetMV("IT_CCHEP",.T.,'')
 Local _cpbr :=  SuperGetMV("IT_PPBR",.T.,'')
 Local _cPBRITLP := AllTrim(SuperGetMV('IT_PBRITLP',.T.,'51'))
 Local _cPBRCLIP := AllTrim(SuperGetMV('IT_PBRCLIP',.T.,'51'))
 Local _cTipoFrete
 Local _cCodUsu := "" As Character

 Default oproc := nil

 If ! _lAutomatico
    _ntot := (Len(_aPeds_Pallet))
 EndIf

 For _Ped := 1 TO Len(_aPeds_Pallet)

    SA2->( DBSetOrder(1) )
    SBZ->( DBSetOrder(1) )
    SC5->( DBSetOrder(1) )
    SC6->( DBSetOrder(1) )
    DA4->( DBSetOrder(1) )

    SC5->( DBGoTo( _aPeds_Pallet[_Ped,1] ))
    TRBPED->( DBGoTo( _aPeds_Pallet[_Ped,2] ))

    If ! _lAutomatico

        If ValType(oproc) = "O"

                  oproc:cCaption := ("Lendo Pedido: "+TRBPED->PED_PEDIDO + " - " + StrZero(_npos,6) + " de " + StrZero(_ntot,6))
                  _npos++
                  ProcessMessages()

        EndIf

    EndIf

     //_cUPalet	:= TRBPED->PED_I_TIPC
    _nPallet    := TRBPED->PED_I_QTPA//Qtde do Pallet

    _cFilOrigem := SC5->C5_FILIAL
    _cPedOrigem := SC5->C5_NUM
    cTipoPV		:= SC5->C5_TIPO
    cCliente	:= SC5->C5_CLIENTE
    cLoja		:= SC5->C5_LOJACLI
    _cTipoFrete := SC5->C5_TPFRETE

    SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
    _cC6_PEDCLI := SC6->C6_PEDCLI
    _cC6_ITEMPC := SC6->C6_ITEMPC
    _cC6_NUMPCOM:= SC6->C6_NUMPCOM

    SA2->(DBSetOrder(1))
    /* CHAMADO 36754 - DESBILITADO POR ENQUANTO
    SA1->(DBSetOrder(3))
    If cTipoPV = "B" .And. SA2->( DBSeek( xFilial("SA2") + SC5->C5_CLIENTE+SC5->C5_LOJACLI ) ) .And. SA1->( DBSeek( xFilial("SA1") + SA2->A2_CGC ) )
       cTipoPV	:= "N"
       cCliente	:= SA1->A1_COD
       cLoja	:= SA1->A1_LOJA
    Else
       _cMensagem:='Erro ao gerar o Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")+", For. / CNPJ: "+SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI +" / "+SA2->A2_CGC+" não encontrados no cadastro de Clientes."
       aAdd( _aLog , {.F.,SC5->C5_NUM,"Nao gerado",_cMensagem  ,"",cTpOper ,_cLocal,SC5->C5_I_FLFNC,SC5->C5_I_FILFT} )
       _aPeds_Pallet[_Ped,3]:=0//Zero para ignorar no proximo processamento/funcao LiberaPedPallCarga(_aPeds_Pallet)
       _lGerouOK:=.F.
       U_ITCONOUT(_cMensagem)
       Loop
    EndIf*/
    _dDtEnt		:= If(SC5->C5_I_DTENT < DATE(),DATE(),SC5->C5_I_DTENT)//Para nao travar a criacao do Pedido de Pallet
    _cLocal     := Posicione('SC6',1,SC5->C5_FILIAL+SC5->C5_NUM,"C6_LOCAL")

    _aCabPV		:= {}
    _aItemPV	:= {}
    _TipoC		:= "C"//1-Pallet Chep
    cTpOper		:= ''
    lMsErroAuto	:= .F.
    nItem		:= 1
    _cDesc      := ""
    _nPreco     := 0
    _cUM	    := ""

    If TRBPED->PED_I_TIPC $ "3,6"//"3-Pallet PBR","6-Pallet PBR Retorno"
       _TipoC:="P"
    EndIf

    If TRBPED->PED_I_TIPC $ "5,6"//"5-Pallet Chep Retorno","6-Pallet PBR Retorno"
       If _cPreCarga = "2" .And. !Empty(_cMotorDAK) .And. Upper(_cTipo) == "PJ-TRANSPORTADORA"
          If DA4->(DBSeek(xFilial("DA4")+_cMotorDAK)) .And. !Empty(DA4->DA4_FORNEC)
                SA1->(DBSetOrder(3))
             If SA2->( DBSeek( xFilial("SA2") + DA4->DA4_FORNEC+DA4->DA4_LOJA ) ) .And. SA1->( DBSeek( xFilial("SA1") + SA2->A2_CGC ) )
                cCliente:= SA1->A1_COD
                cLoja	:= SA1->A1_LOJA
             Else
                _cMensagem:='Erro ao gerar o Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")+", For. / CNPJ: "+DA4->DA4_FORNEC+" / "+DA4->DA4_LOJA+" / "+SA2->A2_CGC+" não encontrados no cadastro de Clientes."
                aAdd( _aLog , {.F.,SC5->C5_NUM,"Nao gerado",_cMensagem  ,"",cTpOper ,_cLocal,SC5->C5_I_FLFNC,SC5->C5_I_FILFT} )
                _aPeds_Pallet[_Ped,3]:=0//Zero para ignorar no proximo processamento/funcao LiberaPedPallCarga(_aPeds_Pallet)
                _lGerouOK:=.F.
                //U_ITCONOUT(_cMensagem) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
                Loop
             EndIf
          Else
             _cMensagem:='Erro ao gerar o Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")+", Motorista: "+_cMotorDAK+" não encontrado ou não tem código de Fornecedor"
             aAdd( _aLog , {.F.,SC5->C5_NUM,"Nao gerado",_cMensagem  ,"",cTpOper ,_cLocal,SC5->C5_I_FLFNC,SC5->C5_I_FILFT} )
             _aPeds_Pallet[_Ped,3]:=0//Zero para ignorar no proximo processamento/funcao LiberaPedPallCarga(_aPeds_Pallet)
             _lGerouOK:=.F.
             //U_ITCONOUT(_cMensagem) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
             Loop
          EndIf
       ElseIf _cPreCarga = "1" .Or. (Empty(_cMotorDAK) .And. Upper(_cTipo) == "PJ-TRANSPORTADORA")
          _cMensagem:='Não gerou o Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")+", Será gerado ao Efetivar a Pre-Carga"
          aAdd( _aLog , {.T.,SC5->C5_NUM,"Nao gerado",_cMensagem  ,"",cTpOper ,_cLocal,SC5->C5_I_FLFNC,SC5->C5_I_FILFT} )
          _aPeds_Pallet[_Ped,3]:=0//Zero para ignorar no proximo processamento/funcao LiberaPedPallCarga(_aPeds_Pallet)
          //U_ITCONOUT(_cMensagem) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
          Loop
       EndIf
    EndIf
    //====================================================================================================
    // Verifica se o Cliente esta com Pallet == Sim
    //====================================================================================================
    If .T.//Upper( _cUPalet ) $ '1,S' .And. M->C5_I_TIPCA <> "2" // Tipo de Carga (C5_TIPCA) => 1=Paletizada; 2=Batida

        //====================================================================================================
        // Verifica se o pedido atual já não está amarrado à um pedido de Pallet
        //====================================================================================================
        If .T.//Empty( SC5->C5_I_NPALE )


            //====================================================================================================
            // Verifica se houveram vendas com quantidade de Pallets
            //====================================================================================================
            If _nPallet > 0
                //====================================================================================================
                // Verifica o Tipo de Pallet e recupera o código do Produto referente
                //====================================================================================================
                If _TipoC == "C"
                    _cProduto := _cchep
                ElseIf _TipoC == "P"
                    _cProduto := _cpbr
                EndIf

                //====================================================================================================
                // Verifica se no cadastro do Cliente É CLIENTE CADASTRADO NA CHEP
                //====================================================================================================
                _clichep := "N"
                SA1->(DBSetOrder(1))
                If SA1->( DBSeek( xFilial("SA1") + ( cCliente + cLoja ) ) )

                    If Len(AllTrim(SA1->A1_I_CCHEP)) == 10
                        _clichep := "S"
                    EndIf

                EndIf

                If _TipoC == "C" //Pallet Chep

                    If cCliente == '000001'

                        If _clichep == "S"
                            cTpOper	:= _citls
                        Else
                            cTpOper	:= _citln
                        EndIf

                    Else

                        If _clichep == "S"
                            cTpOper	:= _cclis
                        Else
                            cTpOper	:= _cclin
                        EndIf

                    EndIf

                ElseIf _TipoC == "P" //Pallet PBR

                    If cCliente == '000001'
                        cTpOper	:= _cPBRITLP
                    Else
                        cTpOper	:= _cPBRCLIP
                    EndIf

                EndIf

                If !_lJob
                   _cCodUsu   := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
                Else
                   _cCodUsu	:= "SISTEMA"
                EndIf

                 //====================================================================================================
                 // Monta o cabeçalho do pedido de Pallet
                 //====================================================================================================
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
                            { "C5_TPFRETE"	, _cTipoFrete		, Nil },; // Tipo de Frete
                            { "C5_I_DTENT"	, _dDtEnt			, Nil },; // Dt de Entrega
                            { "C5_I_CDUSU" 	, _cCodUsu	      , Nil }} // Codigo Usuario

                //====================================================================================================
                // Quando Pedido de Pallet Retorno e For Troca Nota o Pedido deve ser gerado na Filial de Carregamento
                //====================================================================================================

                If TRBPED->PED_I_TIPC $ "1,3,4"
                    aAdd( _aCabPV, { "C5_I_TRCNF", If(Empty(SC5->C5_I_TRCNF),"N",SC5->C5_I_TRCNF), Nil } )
                    aAdd( _aCabPV, { "C5_I_FILFT", SC5->C5_I_FILFT, Nil } )
                    aAdd( _aCabPV, { "C5_I_FLFNC", SC5->C5_I_FLFNC, Nil } )
                EndIf

                If SC5->(FIELDPOS( "C5_I_CDTMS" )) > 0
                   aAdd( _aCabPV, { "C5_I_CDTMS", SC5->C5_I_CDTMS, Nil } )
                EndIf

                //================================================================================
                // Localiza armazém do produto
                //================================================================================

                If !_cLocal $ AllTrim(SuperGetMV('IT_LOCPPAL',.T.,"36,38,40,50" ))

                  _cLocal := ""
                  If SBZ->( DBSeek( xFilial('SBZ') + _cProduto ) )
                     _cLocal := SBZ->BZ_LOCPAD
                  EndIf

                EndIf

                //================================================================================
                // Localiza nome do produto, preço e UM
                //================================================================================
                SB1->(DBSetOrder(1))
                If SB1->(DBSeek(xFilial("SB1")+_cProduto))
                   _cDesc := AllTrim(SB1->B1_DESC)
                   _nPreco:= SB1->B1_PRV1
                   _cUM	  := SB1->B1_UM
                EndIf

                _nTotVlrPal   := _nPallet * _nPreco

                //====================================================================================================
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
                                    { "C6_QTDLIB"	, 0						, Nil },; // Quantidade Liberada
                                    { "C6_PEDCLI" 	, _cC6_PEDCLI           , Nil },;
                                    { "C6_ITEMPC"   , _cC6_ITEMPC           , Nil },;
                                    { "C6_NUMPCOM"  , _cC6_NUMPCOM          , Nil }})

                //====================================================================================================
                // Geração do  pedido de Pallet
                MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItemPV , 3 )

                If lMsErroAuto

                    If ( __lSx8 )
                        RollBackSx8()
                    EndIf

                    If ! _lAutomatico
                       _cMensagem:="Erro: ["+AllTrim(MostraErro())+"]"
                    Else
                       _cMsgEfetiva := " Pedido_"+AllTrim(_cPedOrigem)+" - "+AllTrim(MostraErro("\system\", "Pedido_"+AllTrim(SC5->C5_NUM)+"_"+DToS(Date())+"_"+StrTran(Time(),":","-")+".log")) // Esta mensagem será retornada na integração com Webservice Italac x RDC.
                       _cMsgEfetiva := " Ocorreram problemas na Geração de Pedidos de Pallet: " + StrTran(_cMsgEfetiva,Chr(10)+Chr(13),"")
                    EndIf

                    If _lAutomatico
                       _cMsgEfetiva := If(SC5->C5_I_TRCNF="S"," (Rotina Troca Nota Fiscal): ","")+_cMsgEfetiva
                       //U_ITCONOUT(_cMsgEfetiva) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
                    Else
                       SC5->( DBGoTo( _aPeds_Pallet[_Ped,1] ))
                       _cMensagem:='Erro ao gerar o Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")+" ,"+_cMensagem
                       _cCliente:=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )

                        aAdd( _aLog , {.F.,SC5->C5_NUM,"Nao gerado",_cMensagem  ,_cCliente,cTpOper ,_cLocal  ,SC5->C5_I_FLFNC      ,SC5->C5_I_FILFT     } )
                    EndIf

                    _aPeds_Pallet[_Ped,3]:=0//Zero para ignorar no proximo processamento/funcao LiberaPedPallCarga(_aPeds_Pallet)
                    _lGerouOK:=.F.
                    Loop //do For

                Else
                    //Regrava por garantia
                    SC5->( RecLock( 'SC5' , .F. ) )
                    SC5->C5_I_NPALE := _cPedOrigem
                    SC5->C5_I_PEDPA := 'S'//É o Pedido de Pallet
                    SC5->C5_I_PEDGE := ''
                    SC5->( MSUnLock() )
                    _cCliente:=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )
                    _cMensagem:='Gerou o Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")
                    //U_ITCONOUT(_cMensagem+": "+SC5->C5_NUM) // Comando removido conforme estabelecido no CheckList de Desenvolvimento.
                     aAdd( _aLog , {.T.,_cPedOrigem,SC5->C5_NUM,_cMensagem   ,_cCliente,cTpOper ,_cLocal  ,SC5->C5_I_FLFNC      ,SC5->C5_I_FILFT     } )

                    SC6->(DBSetOrder(1))
                    SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )//Posiciono por garantia
                    _aPeds_Pallet[_Ped,3]:=SC5->(RECNO())//3-Recno do Pedido Novo de Pallet
                    _aPeds_Pallet[_Ped,4]:=_cLocal       //4-Local do Pedido do Pallet
                    _aPeds_Pallet[_Ped,5]:=SC6->(RECNO())//5-Recno do Pedido Novo de Pallet

                    //====================================================================================================
                    // Faz a amarração do pedido de origem no pedido de Pallet
                    //====================================================================================================
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

        //Else

            //U_ITCONOUT("Pedido:"+_cPedOrigem+" sem quantidade de Pallet")// Comando removido conforme estabelecido no CheckList de Desenvolvimento.

        EndIf

    EndIf

 Next

 SA1->(DBSetOrder(1))

Return _lGerouOK

/*
===============================================================================================================================
Programa--------: LiberaPedPallCarga(_aPeds_Pallet,_lAutomatico)
Autor-----------: Alex Wallauer
Data da Criacao-: 02/09/2016
Descrição-------: Libera Pedido de Pallet
Parametros------: Lista dos pedidos
                  _lautomatico - se está rodando em schedule ou não
                  oproc - objeto da barra de processamento
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================
*/
Static Function LiberaPedPallCarga(_aPeds_Pallet,_lAutomatico, oproc)
 Local _cCliente,_Ped,_nQtdLib
 Local lErroSC9:=.F.,lOK:=.T.
 Local _ntot := 0
 Local _npos := 1

 Default _lAutomatico := .F.
 Default oproc := nil

 If ! _lAutomatico
    _ntot := (Len(_aPeds_Pallet))
 EndIf

 SC6->( DBSetOrder(1) )
 SC9->( DBSetOrder(1) )

 For _Ped := 1 TO Len(_aPeds_Pallet)

    If _aPeds_Pallet[_Ped,3] = 0//Nao gerou o Pedido Pallet novo
       Loop
    EndIf

    TRBPED->( DBGoTo( _aPeds_Pallet[_Ped,2] ))
    SC5->( DBGoTo( _aPeds_Pallet[_Ped,3] ))//Pedido Pallet novo

    If ! _lAutomatico

              If ValType(oproc) = "O"

                  oproc:cCaption := ("Lendo Pedido: "+SC5->C5_NUM + " - " + StrZero(_npos,6) + " de " + StrZero(_ntot,6))
                  _npos++
                  ProcessMessages()

              EndIf

     EndIf

    //====================================================================================================
    // Liberaoca de Pedido - reserva de estoque
    //====================================================================================================
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

    _cCliente:=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )
    lBloqEstoque:=lBloqCredito:=lErroSC9:=.F.
    lOK:=.T.
    If lMsErroAuto .Or. ( lErroSC9:=Ver_SC9(SC5->C5_FILIAL+SC5->C5_NUM) )

       If lErroSC9
          _cMensagem:='Liberou o Ped. Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF) ","")+", mas com Bloqueio de"+If(lBloqEstoque," Estoque","")+If(lBloqCredito," Credito","")
       Else
          _cMensagem:='Erro ao liberar o Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")
       EndIf

       _lGerouOK:=lOK:=.F.

    Else

       If SC5->C5_LIBEROK # "S"
          SC5->(RecLock("SC5",.F.))
          SC5->C5_LIBEROK:="S"
          SC5->(MSUnLock())
       EndIf

        _cMensagem:='Liberou Pedido Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")

    EndIf

    //dd( _aLog , {" ",'Pedido O'        ,'Pedido G' ,'Movimentacao','Cliente',Operacao      ,'Armazem'            ,'Filial Carregamento','Filial Faturamento'} )
    aAdd( _aLog , {lOK,TRBPED->PED_PEDIDO,SC5->C5_NUM,_cMensagem    ,_cCliente,SC5->C5_I_OPER,_aPeds_Pallet[_Ped,4],SC5->C5_I_FLFNC      ,SC5->C5_I_FILFT     } )


 Next

Return .T.
/*
===============================================================================================================================
Programa--------: IncliPedPallCarga(_aPeds_Carga,lEfetiva_Pre_Carga,_lAutomatico)
Autor-----------: Alex Wallauer
Data da Criacao-: 18/08/2016
Descrição-------: Libera e Inclui Pedido de Pallet da Carga
Parametros------: Lista dos pedidos , Efetiva Pre-Carga: .T. ou .F. / oproc - objeto da barra de processamento
Retorno---------: Lógico (.T.) Se tudo OK (.F.) Se deu erro
===============================================================================================================================*/
Static Function IncliPedPallCarga(_aPeds_Pallet,lEfetiva_Pre_Carga,_lAutomatico,oproc)
 Local _cCliente,_Ped,_nCpo
 Local _ntot := 0
 Local _npos := 1
 Default _lAutomatico := .F.
 Default oproc := nil

 If ! _lAutomatico
    _ntot := Len(_aPeds_Pallet)
 EndIf

 For _Ped := 1 TO Len(_aPeds_Pallet)

    If _aPeds_Pallet[_Ped,3] = 0//Nao gerou o Pedido Pallet novo
       Loop
    EndIf

    TRBPED->( DBGoTo( _aPeds_Pallet[_Ped,2] ))
    SC5->( DBGoTo( _aPeds_Pallet[_Ped,3] ))//Pedido Pallet novo
    SC6->( DBGoTo( _aPeds_Pallet[_Ped,5] ))//Item Pedido Pallet novo

    If ! _lAutomatico

        If ValType(oproc) = "O"

              oproc:cCaption := ("Lendo Pedido: "+SC5->C5_NUM + " - " + StrZero(_npos,6) + " de " + StrZero(_ntot,6))
              _npos++
               ProcessMessages()

        EndIf


    EndIf

    _cCliente :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )
    _cMensagem:='Inclusao na Carga do Ped. Novo de Pallet'+If(SC5->C5_I_TRCNF="S"," (Troca NF)","")

    //dd( _aLog    , {" ",'Pedido O'        ,'Pedido G'  ,'Movimentacao','Cliente',Operacao      ,'Armazem'            ,'Filial Carregamento','Filial Faturamento'} )
    aAdd( _aLog    , {.T.,TRBPED->PED_PEDIDO,SC5->C5_NUM ,_cMensagem    ,_cCliente,SC5->C5_I_OPER,_aPeds_Pallet[_Ped,4],SC5->C5_I_FLFNC      ,SC5->C5_I_FILFT} )

    _aConteudos:={}
    For _nCpo := 1 TO TRBPED->( FCOUNT() )
        aAdd(_aConteudos,TRBPED->( FIELDGET(_nCpo) ))
    Next
    TRBPED->( DBAPPEND() )
    For _nCpo := 1 TO Len(_aConteudos)
        TRBPED->( FIELDPUT(_nCpo,_aConteudos[_nCpo]) )
    Next

    If lEfetiva_Pre_Carga

       TRBPED->PED_PEDIDO:=SC5->C5_NUM
       TRBPED->PED_CODCLI:=SC5->C5_CLIENTE
       TRBPED->PED_LOJA  :=SC5->C5_LOJAENT
       TRBPED->PED_PESO  :=SC5->C5_I_PESBR
       TRBPED->PED_VALOR :=SC6->C6_VALOR
       TRBPED->PED_QTDLIB:=SC6->C6_QTDVEN

    Else

       TRBPED->PED_PEDIDO:=SC5->C5_NUM
       TRBPED->PED_MARCA :=""//Desmarca para marcar abaixo
       TRBPED->PED_PESO  :=SC5->C5_I_PESBR
       TRBPED->PED_VALOR :=SC6->C6_VALOR
       TRBPED->PED_VOLUM :=0//Volume vem zerado do Pedido Orginal
       TRBPED->PED_QTDLIB:=SC6->C6_QTDVEN
       If TRBPED->(FIELDPOS("PED_I_FROL")) > 0
          TRBPED->PED_I_FROL:=0//Zera o campo de Frete do OL para não duplicar o valor do frete OL Total
       EndIf

       EVAL(_bMarcaTRB)//Simula Excutar os 2 cliques do Browse de selecao de Pedidos para usar apos incliir linha no TRB nova

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
==============================================================================================================================
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
Programa--------: OM200PegaObs(_cObsEmail)
Autor-----------: Alex Wallauer
Data da Criacao-: 20/09/2016
Descrição-------: Get da observacao do e-mail
Parametros------: _cObsEmail variavel da observação
Retorno---------: Lógico (.F.) Se OK (.T.) Se Cancelou
===============================================================================================================================*/
Static Function OM200PegaObs(_cObsEmail)
 Local oDlgEmail,_lOK:=.T.
 Local _nLinha := 15
 Local _nPula  := 15

 DEFINE MSDIALOG oDlgEmail TITLE "Observações no Corpo do E-mail do WF" From 000,000 To 165,600 Pixel

     @_nLinha,005 Say "Obs. E-mail:"
     @_nLinha,045 GET _cObsEmail MEMO HSCROLL SIZE 250,33 PIXEL
     _nLinha+=_nPula+_nPula+_nPula

     @ _nLinha,100 Button "OK"      Size 36,16 Action (If(MSGYESNO('Confirma o envio do E-mail de WF de Carga ?',"WF de Carga"), (oDlgEmail:End(),_lOK:=.T.) , ))
     @ _nLinha,175 Button "Cancela" Size 36,16 Action (oDlgEmail:End(),_lOK:=.F.)

 ACTIVATE MSDIALOG oDlgEmail CENTERED

 If !_lOK
    Return .F.
 EndIf

Return .T.


/*
===============================================================================================================================
Programa--------: BuscaEmail(_lAutomatico,_cMailUser)
Autor-----------: Alex Wallauer
Data da Criacao-: 20/09/2016
Descrição-------: Trata emails
Parametros------: _lAutomatico: logico ,_cMailUser : email do usuario
Retorno---------: Emails
===============================================================================================================================*/
Static Function BuscaEmail(_lAutomatico,_cMailUser)
 Local _cEmail := AllTrim(SuperGetMV("IT_WFCARGA",.T.,""))
 //=========================================================================================
 // Concatena o e-mail do usuário que criou a carga através da rotina de
 // integração RDC via webservice. A variável _cMailUsrCarga foi definida fonte AOMS074.PRW
 //=========================================================================================
If _lAutomatico
    If Type("_cMailUsrCarga") == "C" .And. !Empty(_cMailUsrCarga)
       _cMailUser := AllTrim(_cMailUsrCarga)
    EndIf
 Else
   If Type('__cUserId') == 'C'
      _cMailUser:= FWSFAllUsers({__cUserID},{'USR_EMAIL'})[1][3]
   EndIf   
 EndIf

 If Empty( _cEmail )//Se o paramentro estiver em branco envia para o usuario
    _cEmail:=_cMailUser
    _cMailUser:=""//Não envia copia
 EndIf

Return _cEmail


/*
===============================================================================================================================
Programa--------: IT_EditCell
Autor-----------: Alex Wallauer
Data da Criacao-: 14/03/2015
Descrição-------: Edita o campo da celula do browse selecionado com um get ou combo box
Parametros------: _xGetValor ,oBrowse As object ,cPict as char ,nCol as numeric ,cF3 as char,lReadOnly as logical, bValid as block ,aItems as array do combo
Retorno---------: .T. se OK .F. se Cancelou
===============================================================================================================================*/
User Function IT_EditCell(_xGetValor ,oBrowse As object ,cPict as char ,nCol as numeric ,cF3 as char,lReadOnly as logical, bValid as block ,aItems as array, cMacro As Char) As Logical
  Local oDlg      := Nil as object
  Local oRect     := tRect():New(0,0,0,0) as object
  Local oGet1     := Nil as object
  Local oBtn      := Nil as object
  Local lCargo    := .F. as logical
  Local nLastKey  := 00 as numeric
  Local aDim      := {} as array

  DEFAULT cPict     := ''
  DEFAULT nCol      := oBrowse:nColPos
  DEFAULT lReadOnly := .F.
  DEFAULT bValid    := {|| .T.}
  DEFAULT cMacro    := "M->CELL"+StrZero(nCol,6)
  
  oBrowse:GetCellRect(nCol,,oRect)   // a janela de edicao deve ficar)
  aDim  := {oRect:nTop,oRect:nLeft,oRect:nBottom,oRect:nRight}

  oDlg     := MSDialog():New(0,0,0,0,'Janela sem borda',,,,nOr(WS_VISIBLE,WS_POPUP),CLR_BLACK,CLR_WHITE,,,.T.,,,,.T.)
  oDlg:nStyle := nOR( DS_MODALFRAME, WS_POPUP, WS_CAPTION, WS_VISIBLE )

  &(cMacro):= _xGetValor

  If ValType(aItems) == "A"
    oGet1       := TComboBox():New(0,0, {|u| If( PCount() > 0 , &(cMacro) := u , &(cMacro) ) } ,aItems,0,0,oDlg,,,,,,.T.,,,.F.,,.F.,,)
    oGet1:bValid:= { || lCargo := Eval(bValid) }
  Else                  // LIN ,[ nCol ], [ bSetGet ]                                         , [ oWnd ], [ nWidth ], [ nHeight ], [ cPict ], [ bValid ], [ nClrFore ], [ nClrBack ], [ oFont ], [ uParam12 ], [ uParam13 ], [ lPixel ], [ uParam15 ], [ uParam16 ], [ bWhen ], [ uParam18 ], [ uParam19 ], [ bChange ], [ lReadOnly ], [ lPassword ], [ uParam23 ], [ cReadVar ], [ uParam25 ], [ uParam26 ], [ uParam27 ], [ lHasButton ], [ lNoButton ], [ uParam30 ], [ cLabelText ], [ nLabelPos ], [ oLabelFont ], [ nLabelColor ], [ cPlaceHold ], [ lPicturePriority ]
    oGet1       := TGet():New(0,0       ,{|u| If( PCount() > 0 , &(cMacro) := u , &(cMacro)) },oDlg     ,0          ,0           ,cPict     ,           ,             ,             ,          ,             ,             ,.T.        ,             ,             ,          ,             ,             ,            ,              ,              ,             ,             ,             ,             ,             ,               ,)
    oGet1:bValid   := { || lCargo := Eval(bValid) }
    oGet1:cF3      := cF3
    oGet1:lReadOnly:= lReadOnly
    // oGet1:lNoButton := .F.
  EndIf
  oGet1:Move(-2,-2, (aDim[ 4 ] - aDim[ 2 ]) - 12, aDim[ 3 ] - aDim[ 1 ] + 4 )

  oBtn       := TButton():New( 0, 0, '', oDlg, , 0, 0, , , .F., .T., .F., , .F., , , .F. )
  oBtn:bGotFocus  := {|| nLastKey := oDlg:nLastKey := VK_RETURN, oDlg:End(0)}

  oGet1:cReadVar  := cMacro

  oDlg:bInit     := { || oDlg:Move(aDim[1],aDim[2],aDim[4]-aDim[2], aDim[3]-aDim[1]) }
  oDlg:Activate(,,,)

  If lCargo
    _xGetValor:= &cMacro
    SetFocus(oBrowse:hWnd)
    //oBrowse:Refresh()
  EndIf

Return( nLastKey <> 0 )


/*
===============================================================================================================================
Programa--------: ITAcertaPeso
Autor-----------: Alex Wallauer
Data da Criacao-: 25/07/2015
Descrição-------: Acerta o peso bruto do pedido e dos itens conforme o cadastro do SB1
Parametros------: _cChavePV: Filial + Pedido de Venda
Retorno---------: _nPesoBrut //Retorna o peso bruto total do pedido
===============================================================================================================================*/
User Function ITAcertaPeso(_cChavePV) As Numeric //_nPesoBrut:=U_ITAcertaPeso ( DAI->DAI_FILIAL + DAI->DAI_PEDIDO )
 Local _nPesoBrut:=0 As Numeric
 Local _nPesoItem:=0 As Numeric
 Local _cFilSB1  := xFilial("SB1") As Char
 _cDados:=""//inicializa antes da função tb
 SC6->( DBSetOrder(1) )
 SC5->( DBSetOrder(1) )
 If !SC6->( DBSeek( _cChavePV ) )
    _cDados +=  "Pedido Nao Achou (SC6): " + AllTrim(_cChavePV)+CRLF
 EndIf
 _nTotValor:=0
 While SC6->( !Eof() ) .And. SC6->C6_FILIAL+SC6->C6_NUM == _cChavePV
    //================================================================================================================================
    // SEMPRE ACERTA O PESO BRUTO DE ACORDO COM O DO CADASTRO DO SB1 PQ ENTRE O PEDIDO E A CARGA PODE TER HAVIDO ALTERACAO...
    //================================================================================================================================
    If Posicione( "SB1" , 1 , _cFilSB1 + SC6->C6_PRODUTO , "B1_I_PCCX" )  > 0  .And.  SC6->C6_I_PTBRU > 0 //...EXCETO SE For PESO VARIADO
       _nPesoItem := SC6->C6_I_PTBRU
       _cDados +=  "Prod Variado: " + AllTrim(SC6->C6_PRODUTO) + " - C6_I_PTBRU: " + Str(SC6->C6_I_PTBRU,19,5)+CRLF
    Else
       _nPesoItem := SB1->B1_PESBRU * SC6->C6_QTDVEN //Peso do Item
       _cDados +=  "Prod antes..: " + AllTrim(SC6->C6_PRODUTO) + " - C6_I_PTBRU: " + Str(SC6->C6_I_PTBRU,19,5) +CRLF
       SC6->(RecLock("SC6",.F.))
       SC6->C6_I_PTBRU:=_nPesoItem 
       SC6->(MSUnLock())
       _cDados +=  "Prod depois.: " + AllTrim(SC6->C6_PRODUTO) + " - C6_I_PTBRU: " + Str(SC6->C6_I_PTBRU,19,5) +CRLF
    EndIf
    _nPesoBrut += _nPesoItem
    _nTotValor += SC6->C6_VALOR
    SC6->( DBSkip() )
 EndDo
 If SC5->( DBSeek( _cChavePV ) )
    _cDados +=  "Pedido Achou (SC5) antes.: " + AllTrim(_cChavePV) + " - C5_I_PESBR: " + Str(SC5->C5_I_PESBR,19,5) + " - C5_PBRUTO: " + Str(SC5->C5_PBRUTO,19,5) +CRLF
    SC5->(RecLock("SC5",.F.))
    SC5->C5_I_PESBR:= _nPesoBrut
    SC5->C5_PBRUTO := _nPesoBrut
    SC5->(MSUnLock())
    _cDados +=  "Pedido Achou (SC5) depois: " + AllTrim(_cChavePV) + " - C5_I_PESBR: " + Str(SC5->C5_I_PESBR,19,5) + " - C5_PBRUTO: " + Str(SC5->C5_PBRUTO,19,5)+CRLF
 Else
    _cDados +=  "Pedido Nao Achou (SC5): " + AllTrim(_cChavePV)+CRLF
 EndIf

Return _nPesoBrut //Retorna o peso bruto total do pedido
