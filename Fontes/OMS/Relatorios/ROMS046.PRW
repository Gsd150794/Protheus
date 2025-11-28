 /*
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                            
------------------------------------------------------------------------------------------------------------------------------- 
Alex Wallauer     | 16/07/2018 | Correção da geração do codigo do GTIN da Etiqueta - Chamado 25439
Alex Wallauer     | 06/02/2019 | Troca de Site para geração de codigo de barra - Chamado 27971
Lucas Borges      | 28/08/2024 | Incluída proteção na classe evitando error.log - Chamado 48314
=============================================================================================================================== 
Analista     - Programador  - Inicio   - Envio    - Chamado - Motivo da Alteração
===============================================================================================================================
Alex         - Igor Melgaço - 02/05/25 - 06/05/25 - 50525   - Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/
#Include "RWMAKE.CH"
#Include "TOTVS.ch"
#Include "RPTDEF.CH"
#Include "FWPrintSetup.ch"

/*
===============================================================================================================================
Programa----------: ROMS046
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/11/2016
===============================================================================================================================
Descrição---------: Emissão de etiquetas de produtos
===============================================================================================================================
Parametros--------: lreimprime - Se verdadeiro reimprime usando dados da ZFW posicionada
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function ROMS046(lreimprime)

Private oDlg, oPrint            	
Private cproduto := Space(Len(ZFW->ZFW_PRODUT))
Private cprodAux := Space(Len(ZFW->ZFW_PRODUT))
Private nquant := 0
Private dprod := Date()
Private dvalid := Date() + Posicione("SBZ", 1, xFilial("SBZ") + cproduto, "BZ_I_DIVLD")//240
Private clote := Space(Len(ZFW->ZFW_LOTE))
Private npeso := 0
Private sai := .T.
Private csequen := Space(7)
Private cPallet := Space(Len(ZFW->ZFW_PALLET))
Default lreimprime := .F.
Private _oBBrowse:=GetMBrowse()

Private _cCaixa  := Space(Len(ZFW->ZFW_CAIXA))
Private _cFilSG1 := xFilial("SG1")
Private _nQtdCxPa:= 0
Private _nTaraEmb:= 0
Private _nTaraCx := 0
Private _cTaras  := ""
Private aret     := {0,0,0}

If lreimprime
	ROMS046E(lreimprime) //Imprime Etiqueta de caixa
Else
	If .not. ZFW->(Eof())
		cproduto:= ZFW->ZFW_PRODUT
		cprodAux:= ZFW->ZFW_PRODUT
		nquant  := ZFW->ZFW_QUANT
		npeso   := ZFW->ZFW_PESO
		clote   := ZFW->ZFW_LOTE
		dprod   := ZFW->ZFW_DPROD
		dvalid  := ZFW->ZFW_DVALID
		If ZFW->ZFW_TIPO = "P"
			U_ITMsg("Ação não permitida para etiqueta de Pallet [ Tipo = P ] ","Atenção","Posicione em uma etiqueta de Caixa [ Tipo = C ]",1)
			Return .F.
		EndIf
	EndIf

	_nTotSB1:=0

	If !ROMS46Val("ANTES_TELA")//Chama para carregar o numero do cPallet e o _nTotSB1
		Return .F.
	EndIf

	While sai

		sai := .F.

		_nLinha:=5
		_nPula :=20
		_nCol1:=5
		_nCol2:=50
		_nCol3:=150
		_nCol4:=200
				
		@ 000, 000 To 200, 660 Dialog oDlg Title "Impressão de Etiquetas Caixa"

		@ _nLinha, _nCol1 Say "Produto:" pixel
		@ _nLinha, _nCol2 Get cproduto Picture "@!" F3 "SB1" VALID existcpo("SB1") .And. ROMS46Val("PRODUTO") Size 060, 010
		@ _nLinha, _nCol2+65 Get _nTotSB1 Picture "@E 999999"  Size 10,08  pixel WHEN .F.
		_nLinha+=_nPula

		@ _nLinha, _nCol1 Say "Quantidade:" pixel
		@ _nLinha, _nCol2 Get nquant Picture "@E 9,999,999"  Size 060, 010  pixel VALID ROMS46Val("QTDE")
		_nLinha+=_nPula

		@ _nLinha, _nCol1 Say "Peso Bruto:"  pixel
		@ _nLinha, _nCol2 Get npeso Picture "@E 9,999,999.999"  Size 060, 010  pixel VALID ROMS46Val("PB")
		_nLinha+=_nPula

		@ _nLinha, _nCol1 Say "Pallet:"  pixel
		@ _nLinha, _nCol2 Get cpallet  Size 060, 011  pixel WHEN .F.
		@ _nLinha, _nCol2+65 Get _nQtdCxPa Picture "@E 999999"  Size 10,08  pixel WHEN .F.
		_nLinha+=_nPula

		@ _nLinha, _nCol1 Say "Caixa:"  pixel
		@ _nLinha, _nCol2 Get _cCaixa  Size 060, 011  pixel WHEN .F.

		_nLinha:=5

		@ _nLinha, _nCol3 Say "Lote:"  pixel
		@ _nLinha, _nCol4 Get clote  VALID NaoVazio(clote) .And. ROMS46Val("LOTE")  Size 050, 010 PIXEL PICTURE AVSX3("ZFW_LOTE",6)
		_nLinha+=_nPula

		@ _nLinha, _nCol3 Say "Data Produção:"  pixel
		@ _nLinha, _nCol4 Get dprod   Size 050, 010  pixel VALID ROMS46Val("DT")
		_nLinha+=_nPula

		@ _nLinha, _nCol3 Say "Data Validade:"  pixel
		@ _nLinha, _nCol4 Get dvalid  Size 050, 010   pixel VALID ROMS46Val("VALIDADE")
		_nLinha+=_nPula

		@ _nLinha, _nCol3 Say "Taras:"  pixel
		@ _nLinha, _nCol4 Get _cTaras  Size 110, 010   pixel WHEN .F.
		_nLinha+=_nPula
	//  Foi retirado pq agora imprimi só o que foi gravado
	//	@ _nLinha, 129 BmpButton Type 06 Action Processa( {|| ROMS046E(lreimprime),_oBBrowse:Refresh() }, "Aguarde...", "Imprimindo etiquetas...",.F.)//Imprimir 
		@ _nLinha, 182 BmpButton Type 13 Action Processa( {|| nRecZFW:=ROMS046G() ,ZFW->(DBGoTo(nRecZFW)) ,_oBBrowse:Refresh() }, "Aguarde...", "Gravando etiquetas...",.F.) //Salvar
		@ _nLinha, 235 BmpButton Type 02 Action oDlg:End()

		Activate Dialog oDlg Centered

	EndDo
	
EndIf

Return 

/*
===============================================================================================================================
Programa----------: ROMS46Val
Autor-------------: Alex Wallauer
Data da Criacao---: 06/07/2017
===============================================================================================================================
Descrição---------: Validacao 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/  
Static Function ROMS46Val(_cCpoOrigem)

Local cquery    := ""
Local cquery2   := ""
Local cquery3   := ""
Local cpalletMAX:= ""
Local _nQtdeVal := Posicione("SBZ", 1, xFilial("SBZ") + cproduto, "BZ_I_DIVLD")//240
DEFAULT _cCpoOrigem  := "PRODUTO_E_LOTE"
Private _nQtePacCX   := 0 // qtde de pacotinhos em 1 caixa
//IVATE _nPesTotCaixa:= 0 // Peso total dos pacotes na caixa
Private _nPesDigCaixa:= 0 // Peso do pacotes digitados
Private _lAutomatico := !(Posicione("SBZ", 1, xFilial("SBZ") + cproduto, "BZ_I_QBLOT") = "N")

If _cCpoOrigem == "DT"
	
	dvalid := dprod + _nQtdeVal
	Return .T.

ElseIf _cCpoOrigem == "VALIDADE"

	If _nQtdeVal = 0 //.AND. ((dvalid - dprod) > 365)
		U_ITMsg("Prazo de validade não cadastrado para esse produto","Atenção","Favor verificar com o setor de cadastrode produtos, a validade cadastrada para esse produto [BZ_I_DIVLD] no cadastro de indicadores.",1)
	    Return .F.
	EndIf

	dvalidAux := dprod + _nQtdeVal 
	If dvalid >= (dvalidAux+5) .Or. dvalid <= (dvalidAux-5)
	   _nDif:=(dvalid-dprod)
		U_ITMsg("A Data de validade desse produto não condiz com a quantidade de dias do cadastro de indicadores [BZ_I_DIVLD].","Atenção","A data de validade deve ser igual a ( data produção + "+AllTrim(Str(_nQtdeVal)) +" ) = "+DToC(dvalidAux)+", a data de validade digita esta a "+AllTrim(Str(_nDif))+" dias da data de produção.",1)
	    Return .F.
	EndIf
	Return .T.
	
ElseIf _cCpoOrigem == "QTDE"
	
	_nQtePacCX:=ROMS046Tot(cproduto,"QTDE",nquant)//preenche a vairavel _nPesDigCaixa
	If nquant # _nQtePacCX
		U_ITMsg("Quantidade digitada deve ser "+AllTrim(Str(_nQtePacCX))+" unidades que cabem em uma caixa","Atenção","Quantidade deve ser igual a "+AllTrim(Str(_nQtePacCX)),1)
	    nquant:=ROMS046Tot(cproduto,"QTDE",0)//preenche a vairavel _nPesDigCaixa
	EndIf
	If !_lAutomatico
		npeso:= _nPesDigCaixa
	EndIf
    aret := ROMS046Q(_cFilSG1)//Calcula peso das embalagens x quantidade digitada

	Return .T.
	
ElseIf _cCpoOrigem == "PB"
	
	If !_lAutomatico
		ROMS046Tot(cproduto,"QTDE",nquant)//preenche a vairavel _nPesDigCaixa
		If npeso > _nPesDigCaixa
			If !U_ITMsg("Peso digitado maior que "+AllTrim(Str(_nPesDigCaixa))+" Kgs que é equivalente a quantidade digitada de "+AllTrim(Str(nquant))+". Deseja continuar?","Atenção",,3,2,2)
			    npeso:=_nPesDigCaixa
				Return .F.
			EndIf
		EndIf
	EndIf
	
	Return .T.

ElseIf _cCpoOrigem == "LOTE"
/*	If !_lAutomatico
	   ZFW->(DBSetOrder(3))
	   If ZFW->(DBSeek(xFilial("ZFW")+_cCaixa+cLote))
	   	  U_ITMsg("Esse lote já esta na caixa "+_cCaixa,"Atenção","Digite outro numero de lote",1)
		  Return .F.
	   EndIf
	EndIf*/
//  Return .T.
EndIf

_nTotSB1:=ROMS046Tot(cproduto)//Quantidade de caixas

//If !_lAutomatico
   If _cCpoOrigem == "PRODUTO" .And. cProdAux # ZFW->ZFW_PRODUT//Trocou de produto
      cProdAux:= ZFW->ZFW_PRODUT
      dprod   := Date()
      dvalid  := Date() + Posicione("SBZ", 1, xFilial("SBZ") + cproduto, "BZ_I_DIVLD")//240
      clote   := Space(Len(ZFW->ZFW_LOTE))
	  nquant  := ROMS046Tot(cproduto,"QTDE",0)//preenche a vairavel _nPesDigCaixa //Quantidade nas caixas
	  npeso   := _nPesDigCaixa
      _cFilSG1 := xFilial("SG1")
      _nTaraEmb:= 0
      _nTaraCx := 0
   EndIf
//EndIf

If _cCpoOrigem == "PRODUTO" .And. !ROMS046Fil(cproduto)//Tenho pegar depois do If de cima por causa das taras
   Return .F.
EndIf

If _cCpoOrigem == "ANTES_TELA"
   _cTaras:= "Caixa: "+AllTrim(TRANS(ZFW->ZFW_TRCAX,"@E 999,999.999"))+" - Embalagem: "+AllTrim(TRANS(ZFW->ZFW_TREMB,"@E 999,999.999"))
Else
   aret   := ROMS046Q(_cFilSG1)//Calcula as _cTaras
EndIf

_cCaixa := ROMS046Caixa(.F.)

cquery := "SELECT MAX(ZFW_PALLET) NUM FROM " + RETSQLNAME("ZFW")
cquery += " WHERE D_E_L_E_T_ = ' ' AND ZFW_FILIAL = '" + xFilial("ZFW")+"'"

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'TSD1', .T., .F.)

If Val(TSD1->NUM) = 0 //Trantamento para o primeiro registro da filial atual
   cPallet:= '0000001'
   TSD1->(DBCloseArea())
   Return .T.
Else
   cpalletMAX:= StrZero(Val(TSD1->NUM),7)
EndIf

cquery2 := "SELECT MAX(ZFW_PALLET) ULTPALLET "
cquery2 += " from " + retsqlname("ZFW") + " WHERE D_E_L_E_T_ = ' ' AND ZFW_FILIAL = '" + xFilial("ZFW") +"'" 
cquery2 += " AND ZFW_PRODUT = '" + cProduto + "'" 
cquery2 += " AND ZFW_LOTE   = '" + cLote + "'" 
cquery2 += " AND ZFW_TIPO   = 'C'" 

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery2), 'TSD2', .T., .F.)

If Val(TSD2->ULTPALLET) = 0//Senão existe produto + lote gera novo numero de pallet

   cPallet:= StrZero(Val(cpalletMAX)+1,7)

Else

   cPallet:= StrZero(Val(TSD2->ULTPALLET),7)//Pega o numero do Pallet e verefica se tá fechado

   cquery3 := "SELECT COUNT(ZFW_PALLET) TEMPALLET "
   cquery3 += " from " + retsqlname("ZFW") + " WHERE D_E_L_E_T_ = ' ' AND ZFW_FILIAL = '" + xFilial("ZFW") +"'" 
   cquery3 += " AND ZFW_PRODUT = '" + cProduto + "'" 
   cquery3 += " AND ZFW_LOTE   = '" + cLote + "'" 
   cquery3 += " AND ZFW_PALLET = '" + cPallet + "'" 
   cQUERY_P:= " AND ZFW_TIPO   = 'P'" 

   dbUseArea(.T., "TOPCONN", TCGenQry(,, (cquery3+cQUERY_P) ), 'TSD3', .T., .F.)

   If TSD3->TEMPALLET > 0//Se o Produto + Lote tem PALLAET FECHADO para o cPallet encontrado gera novo numero de pallet
      cPallet:= StrZero(Val(cpalletMAX)+1,7)
   Else
      cQUERY_C := " AND ZFW_TIPO   = 'C'" 
      dbUseArea(.T., "TOPCONN", TCGenQry(,, (cquery3+cQUERY_C)) , 'TSD4', .T., .F.)   
      _nQtdCxPa:= TSD4->TEMPALLET
      TSD4->(DBCloseArea())
   EndIf

   TSD3->(DBCloseArea())
   
EndIf

TSD1->(DBCloseArea())
TSD2->(DBCloseArea())
DBSelectArea("ZFW")

Return .T.

/*
===============================================================================================================================
Programa----------: ROMS046E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/11/2016
===============================================================================================================================
Descrição---------: Impressão de etiquetas de produtos
===============================================================================================================================
Parametros--------: lreimprime - se é reimpressão de etiqueta ou nova etiqueta
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function ROMS046E(lreimprime)

Local sai := .T.
Local cpalini := Space(7)
Local cpalfim := Space(7)
Local cini := Space(7)
Local cfim := Space(7)

Private nlinha := 40
Private ncoluna := 20

Private ntamh := 1120
Private ntamv := 1680
Private aregs := {}

If .not. lreimprime
	sai := .T.
	ROMS046Z('0','0','0','0',nil,.F.)
Else
	sai := .T.

	While sai

		sai    := .F.
		cpalini:= ZFW->ZFW_PALLET
		cpalfim:= ZFW->ZFW_PALLET
		cini   := ZFW->ZFW_SEQUEN
		cfim   := ZFW->ZFW_SEQUEN
		_nLin:=1

		lTodas:=U_ITMsg("Imprmir todas as etiquetas do Pallet?",'Atenção!',,3,2,2)
			
		@ 000, 000 To 300, 350 Dialog oDlg Title "Reimpressão de Etiquetas"
		
		@ _nLin, 001 Say "Pallet inicial:"
		@ _nLin, 010 Get cpalini Picture "9999999"  Size 060, 010
		_nLin+=1
		@ _nLin, 001 Say "Pallet final:"
		@ _nLin, 010 Get cpalfim Picture "9999999"  Size 060, 010
		_nLin+=1
		If !lTodas
		@ _nLin, 001 Say "Seq Inicial:"
		@ _nLin, 010 Get cini Picture "9999999"  Size 060, 010
			_nLin+=1
		@ _nLin, 001 Say "Seq Final:"
		@ _nLin, 010 Get cfim Picture "9999999"  Size 060, 010
		Else
		cini:=""
		cfim:=""
		EndIf
		
		@ 0080, 010 BmpButton Type 1 Action Processa( {|| ROMS046Z(cpalini,cpalfim,cini,cfim,oDlg,.T.) }, "Aguarde...", "Imprimindo etiquetas...",.F.)
		@ 0080, 085 BmpButton Type 2 Action Close(oDlg)

		Activate Dialog oDlg Centered

	EndDo

EndIf

//Zera sequencia para não correr risco de gravar repetida
csequen := Space(7)

Return

/*
===============================================================================================================================
Programa----------: ROMS046Q
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/11/2016
===============================================================================================================================
Descrição---------: Carrega peso de embalagens
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Array com peso da caixa, peso da embalagem 
===============================================================================================================================
*/  
Static Function ROMS046Q(_cFilSG1)

Local aret := {0,0,0}
Local cquery:= ""

If Empty(cproduto)
   Return aret
EndIf

If _nTaraEmb # 0 .And. _nTaraCx # 0
    aret := {_nTaraCx,_nTaraEmb,_nTaraEmb+_nTaraCx}
    _cTaras  :="Caixa: "+AllTrim(TRANS(_nTaraCx,"@E 999,999.999"))+" - Embalagem: "+AllTrim(TRANS(_nTaraEmb,"@E 999,999.999"))
    Return aret
EndIf

cquery := "select G1_FILIAL,G1_COD,G1_COMP,G1_TRT,G1_QUANT,G1_REVINI,G1_REVFIM,"
cquery += "(SELECT MAX(G1_REVfim) FROM " + retsqlname("SG1") + " SG1T2 WHERE SG1T2.D_E_L_E_T_ = ' ' AND sg1t2.g1_revfim <> 'ZZZ'"
cquery += " and sg1t2.g1_cod = sg1.g1_cod and sg1t2.g1_filial = '" + _cFilSG1 + "') revi,"
cquery += " sg1.g1_quant/(select bz_QB from " + retsqlname("SBZ") + " sbz where sbz.D_E_L_E_T_ = ' ' and sbz.bz_cod = sg1.g1_cod and sbz.bz_filial = '" + _cFilSG1 + "') quant, "
cquery += " (SELECT B1_PESO FROM " + RETSQLNAME("SB1") + " SB1 WHERE SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = SG1.G1_COMP) PESO, "
//cquery += " (sg1.g1_quant/(select bz_QB from " + retsqlname("SBZ") + " sbz where sbz.D_E_L_E_T_ = ' ' and sbz.bz_cod = sg1.g1_cod and sbz.bz_filial = '" + xFilial("SBZ") + "')) PESO,"
cquery += " (SELECT BZ_QB FROM " + retsqlname("SBZ") + " sbz where sbz.D_E_L_E_T_ = ' ' and sbz.bz_cod = sg1.g1_cod and sbz.bz_filial = '" + _cFilSG1 + "') QB,"
//cquery += " (SELECT B1_TIPO FROM " + RETSQLNAME("SB1") + " SB12 WHERE SB12.D_E_L_E_T_ = ' ' AND SB12.B1_COD = SG1.G1_COMP) TIPO,"
cquery += " (SELECT B1_DESC FROM " + RETSQLNAME("SB1") + " SB13 WHERE SB13.D_E_L_E_T_ = ' ' AND SB13.B1_COD = SG1.G1_COMP) DESCR,"
cquery += " (SELECT B1_I_QESP FROM " + RETSQLNAME("SB1") + " SB14 WHERE SB14.D_E_L_E_T_ = ' ' AND SB14.B1_COD = SG1.G1_COMP) QESP"
cquery += " from " + retsqlname("SG1") + " sg1" 
cquery += " where sg1.D_E_L_E_T_ = ' ' and sg1.g1_filial = '" + _cFilSG1 + "'" //xFilial("SG1")
cquery += "                            and sg1.g1_cod = '" + AllTrim(cproduto) + "'" 
cquery += "                            and (select b1_tipo from " + retsqlname("SB1") + " sb1 where sb1.D_E_L_E_T_ = ' ' and sb1.b1_cod = sg1.g1_COMP) = 'EM'" 
cquery += "                            and (((SELECT MAX(G1_REVfim) FROM " + retsqlname("SG1") + " SG1T WHERE SG1T.D_E_L_E_T_ = ' ' and sg1t.g1_filial = '" + _cFilSG1 + "'" //xFilial("SG1")
cquery += "                                                                                      AND sg1t.g1_revfim <> 'ZZZ'" 
cquery += "                                                                                      and sg1t.g1_cod = sg1.g1_cod) = sg1.g1_revfim )" 
cquery += "                                                                                      or sg1.g1_revfim = 'ZZZ')"

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'TSG1', .T., .F.)
DBSelectArea("TSG1")

While .not. TSG1->(Eof())

	aret[3] += TSG1->PESO
	
	If "CX" $ TSG1->DESCR .Or. "CAIXA" $ TSG1->DESCR  .Or. "CARTELA" $ TSG1->DESCR
	
	  aret[1] += TSG1->PESO
	  
	ElseIf !Empty(TSG1->QESP)
	
	  aret[2] += TSG1->PESO * nquant
	
	EndIf                                                                               	
	
	TSG1->(DBSkip())
	
EndDo

TSG1->(DBCloseArea())

_cTaras  :="Caixa: "+AllTrim(TRANS(aret[1],"@E 999,999.999"))+" - Embalagem: "+AllTrim(TRANS(aret[2],"@E 999,999.999"))

Return aret

/*
===============================================================================================================================
Programa----------: ROMS046G
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/09/2016
===============================================================================================================================
Descrição---------: Grava dados da etiqueta de caixa
===============================================================================================================================
Uso---------------: Italac
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  

Static Function ROMS046G()

If !ROMS46Val("QTDE") .Or. !ROMS46Val("LOTE")
   Return ZFW->(RECNO())
EndIf
If csequen == Space(7) //Se ainda não carregou sequencia faz agora
   csequen:= getsxenum("ZFW","ZFW_SEQUEN")
   Confirmsx8()
EndIf

ZFW->(RecLock("ZFW", .T.))

ZFW->ZFW_SEQUEN:= csequen
ZFW->ZFW_PESO  := npeso
ZFW->ZFW_FILIAL:= xFilial("ZFW")
ZFW->ZFW_PRODUT:= cproduto
ZFW->ZFW_QUANT := nquant
ZFW->ZFW_LOTE  := clote
ZFW->ZFW_DPROD := dprod
ZFW->ZFW_DVALID:= dvalid
ZFW->ZFW_TIPO  := "C" 
ZFW->ZFW_PALLET:= cpallet
ZFW->ZFW_CAIXA := _cCaixa
//aret:={_nTaraCx,_nTaraEmb,_nTaraEmb+_nTaraCx}
ZFW->ZFW_TREMB := If(_nTaraEmb#0,_nTaraEmb,aret[2])
ZFW->ZFW_TRCAX := If(_nTaraCx #0,_nTaraCx ,aret[1])

ZFW->(MSUnLock())

cPallet := ROMS046VP()
_cCaixa := ROMS046Caixa(.F.)

csequen:=Space(7)//Zera sequencia para não correr risco de gravar repetida

nRecZFW:=ZFW->(RECNO())
If nRecZFW > 15//numero de linhas do Browse
   nRecZFW:=(nRecZFW-15)//Posição do primeiro registro do Browse onde deixa o utimo registro da tabela na ultima linha do browse
EndIf

Return nRecZFW

/*
===============================================================================================================================
Programa----------: ROMS046VP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/11/2016
===============================================================================================================================
Descrição---------: Verifica número de pallet do novo registro
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: string com número do pallet
===============================================================================================================================
*/  
Static Function ROMS046vp()

Local cpallet := '0000000'
Local cquery  := ""
Local cpalletu:= "0000000"

cquery := "SELECT ZFW_PALLET, "
cquery += "	COUNT(ZFW_PALLET) QTDE,"
cquery += "	SUM(ZFW_PESO)     PESO,"
cquery += " SUM(ZFW_QUANT)    quant,"
cquery += " SUM(ZFW_TRCAX)    ZCAIXA,"
cquery += " SUM(ZFW_TREMB)    ZEMB"
cquery += " from " + retsqlname("ZFW") + " where D_E_L_E_T_ = ' ' and zfw_filial = '" + xFilial("ZFW") +"'" 
cquery += " and zfw_produt = '" + cproduto + "'" 
cquery += " and zfw_lote   = '" + clote + "'" 
cquery += " and zfw_dprod  = '" + DToS(dprod) + "'" 
cquery += " and zfw_dvalid = '" + DToS(dvalid) + "'"
cquery += " and zfw_tipo   = 'C'" 
cquery += " group by zfw_pallet"
cquery += "	ORDER BY zfw_pallet"

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'TSD1', .T., .F.)
DBSelectArea("TSD1")

_nTotSB1:=ROMS046Tot(cproduto)//(Posicione("SB1",1,xFilial("SB1")+cproduto,"B1_I_CXPAL") / SB1->B1_I_QT3UM)
//Procura pallet incompleto
If .not. TSD1->(Eof())

	While .not. TSD1->(Eof())
	
		_nTotC   := TSD1->QTDE
		_nQtdCxPa:= TSD1->QTDE
		If _nTotC < _nTotSB1
			cpallet := TSD1->ZFW_PALLET
			Exit
		EndIf
		
		//Guarda dados do ultimo pallet
		npesou   := TSD1->PESO
		nqtdeu   := TSD1->QTDE
		cpalletu := TSD1->ZFW_PALLET
        nTrCaixa := TSD1->ZCAIXA
        nTrEmb   := TSD1->ZEMB
		
		TSD1->(DBSkip())
		
	EndDo
	
EndIf

TSD1->(DBCloseArea())

//Se não achou pallet incompleto faz um novo pallet
If cpallet == '0000000'

	cquery := "select max(zfw_pallet) num from " + retsqlname("ZFW") + " where D_E_L_E_T_ = ' ' and zfw_filial = '" + xFilial("ZFW") +"'"   

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'TSD1', .T., .F.)
	DBSelectArea("TSD1")

	If TSD1->(Eof()) 
		cpallet := '0000001'
	Else
		//Antes de criar novo pallet atualiza registro do último pallet sendo criado
		ZFW->(DBSetOrder(2))
		
		If ZFW->(DBSeek(xFilial("ZFW")+"C"+cpalletu))
			
				csequen := getsxenum("ZFW","ZFW_SEQUEN")
				ConfirmSX8()
				
				ZFW->(RecLock("ZFW", .T.))
				
				ZFW->ZFW_FILIAL := xFilial("ZFW")
				ZFW->ZFW_PESO   := npesou
				ZFW->ZFW_QUANT  := nqtdeu
				ZFW->ZFW_SEQUEN := csequen  //csequenu//Troquei pq agora gera o Pallet por ultimo
				ZFW->ZFW_PRODUT := cproduto //cprodutou
				ZFW->ZFW_LOTE   := clote    //cloteu
				ZFW->ZFW_DPROD  := dprod    //dprodu
				ZFW->ZFW_DVALID := dvalid   //dvalidu
				ZFW->ZFW_TIPO   := "P" 
				ZFW->ZFW_PALLET := cpalletu
                ZFW->ZFW_CAIXA  := _cCaixa
                ZFW->ZFW_TREMB  := nTrEmb//If(_nTaraEmb#0,_nTaraEmb,aret[2])
                ZFW->ZFW_TRCAX  := nTrCaixa//If(_nTaraCx #0,_nTaraCx ,aret[1])
				ZFW->(MSUnLock())
				
		EndIf
		
		ZFW->(DBSetOrder(1))
		cpallet := StrZero(Val(TSD1->NUM)+1,7)
		
	EndIf
	
	TSD1->(DBCloseArea())
	
EndIf

Return cpallet

/*
===============================================================================================================================
Programa----------: ROMS046Z
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/09/2016
===============================================================================================================================
Descrição---------: Impressão de multiplas etiquetas
===============================================================================================================================
Uso---------------: Italac
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function ROMS046Z(cpalini, cpalfim,cini,cfim,odlg,lreimprime)

Local cquery := "",_nI , ni

Private aregs := {}

If lreimprime
   cproduto:=ZFW->ZFW_PRODUT
EndIf

If lreimprime

	cquery := "select r_e_c_n_o_ num from " + retsqlname("ZFW")
	cquery += " where D_E_L_E_T_ = ' ' AND ZFW_FILIAL = '" + xFilial("ZFW")+"' and ZFW_PALLET >= '" + AllTrim(cpalini) + "' and  ZFW_PALLET <= '" + AllTrim(cpalfim) + "'" 
	cquery += " and ZFW_TIPO = 'C'"
	If !Empty(cini)
	   cquery += " and ZFW_SEQUEN >= '" + AllTrim(cini) + "' "
	EndIf
	If !Empty(cfim)
	   cquery += " and ZFW_SEQUEN <= '" + AllTrim(cfim) + "' "
	EndIf

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'TSD1', .T., .F.)
	DBSelectArea("TSD1")

	If TSD1->(Eof()) 

		U_ITMsg("Não foram encontradas etiquetas!",,,1)
  
		TSD1->(DBCloseArea())
  
		Return
  
	EndIf

	While .not. TSD1->(Eof())


		aAdd(aregs,TSD1->NUM)
  
		TSD1->(DBSkip())
  
	EndDo

	TSD1->(DBCloseArea())

	close(odlg)

Else

	//Se For impressão nova só deixa uma passagem no Loop 

	aregs := {1}

EndIf

Private _lSite:=.F.//U_ITMsg("Origem do Codigo de Barra do Site ? ",'Atenção!',,3,2,2)

If _lSite
	ntamv    :=1680
	ntamh    :=1120
	nLinMeio :=0500 
	ncoluna  :=20
	nTamFonte:=00
	nlinhaIni:=40
	nLinhAux1:=00
	nLinhAux2:=00
	nColuAux1:=500
	_nMeioE  :=250
	_nMeio   :=500
	_nMeioD  :=800
	_nEsqu1  :=010
	_nEsqu2  :=nLinMeio + 10

	oPrint := TAVPrinter():New("Etiquetas p/ produtos")                     
	oPrint :SetPortrait()                  // Fixa a Impressao em Retrato
	oPrint :Setup()

Else
	ntamv    :=1550//ALTURA DAS LINHA LATERAIS 
	ntamh    :=1140//LARGURA DA ETIQUETA
	nLinMeio  :=0460 
	ncoluna  :=15
	nTamFonte:=04
	nlinhaIni:=35
	nLinhAux1:=35
	nLinhAux2:=15
	nColuAux1:=100
	_nMeio   :=010
	_nMeioE  :=010
	_nMeioD  :=nLinMeio+05
	_nEsqu1  :=010
	_nEsqu2  :=nLinMeio+05

	cLocal:= GetTempPath()

	cFileName:="ROM046_"
	cFileName+=DToS( Date() ) + "_"
	cFileName+=StrTran(TIME(), ":" , "" )
	cFileName:=cFileName+".pdf"

	oPrint:= FwMsPrinter():New(cFileName, IMP_PDF , .T., cLocal , .T.)//, .T., NIL, NIL, NIL, NIL, NIL, .F., NIL)
	oPrint:cPathPDF := cLocal	// Caso seja utilizada impressão em IMP_PDF
	oPrint:SetPortrait()        // Fixa a Impressao em Retrato
	oPrint:Setup()

	If Upper(oPrint:cPathPDF) == "C:\" .Or. Empty(oPrint:cPathPDF)
	   oPrint:cPathPDF := cLocal
	EndIf
	
	If oPrint:nModalResult = 2//APERTOU O CANCELA
	   Return .F.
	EndIf
EndIf   

oFont10  := TFont():New("Arial", 9, (10+nTamFonte  ), .T., .F., 5,,, .T., .F.,,,,,, oPrint)
oFont10n := TFont():New("Arial", 9, (10+nTamFonte  ), .T., .T., 5,,, .T., .F.,,,,,, oPrint)
oFont12n := TFont():New("Arial", 9, (12+nTamFonte+1), .T., .T., 5,,, .T., .F.,,,,,, oPrint)//TITULO

ni := 1

cerros := ""
ProcRegua(Len(aregs))

For ni := 1 TO  Len(aregs)
	
	ZFW->(DBGoTo(aregs[ni]))
	nlinha := nlinhaIni
	nRecZFW:=ZFW->(RECNO())
	
	IncProc("Imprimindo etiqueta " + StrZero(ni,2) + " de " + StrZero(Len(aregs),2))
	
	If lreimprime
		
		cproduto := ZFW->ZFW_PRODUT
		nquant   := ZFW->ZFW_QUANT
		npeso    := ZFW->ZFW_PESO
		clote    := ZFW->ZFW_LOTE
		dprod    := ZFW->ZFW_DPROD
		dvalid   := ZFW->ZFW_DVALID
		
	EndIf
	
	//Localiza produto selecionado
	Posicione("SB1",1,xFilial("SB1")+cproduto,"B1_COD")
	
	If Empty(SB1->B1_CONV)
		_lLayoutVariavel:=.T.
	Else
		_lLayoutVariavel:=.F.
	EndIf
	
	If Len(AllTrim(SB1->B1_I_DUN14)) < 13
		
		If !(cproduto$cerros)
			
			U_ITMsg("Produto sem código DUN14 válido","Atenção","Preencha o campo "+AVSX3("B1_I_DUN14",5)+" no cadastro do produto: "+cproduto,3)
			
			cerros += "|" + cproduto
			
		EndIf
		
		ni++
		
		Loop
		
	EndIf
	
	
	//Calcula peso das embalagens
	//aret := ROMS046Q(_cFilSG1)
	
	oPrint:StartPage()              // Inicializa a Pagina de Impressao
	
//	oPrint:Line(nlinhaIni,ncoluna - 5     , nlinha + ntamv , ncoluna - 5     )//LINHA LATERAL ESQUERDA 
//	oPrint:Line(nlinhaIni,ncoluna + ntamh , nlinha + ntamv , ncoluna + ntamh )//LINHA LATERAL DIRETA
	
	oPrint:Line(nlinha,ncoluna - 5 , nlinha , ncoluna + ntamh)//LINHA INICIAL
	
	nLinha += 010
	
	oPrint:Say(nLinha+nLinhAux1, nColuna + nColuAux1,"Goiasminas Indústria de Laticínios Ltda.", oFont12n,,,,2)
	
	nLinha += 060
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
	
	If _lLayoutVariavel // ***************   LAYOUT  VARIAVEL  ****************************
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "GTIN", oFont10n)//200
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, "Peso Líquido", oFont10n)//610
		
		oPrint:Line(nlinha , ncoluna + nLinMeio, nlinha + 110,  ncoluna + nLinMeio)
		
		nLinha += 060-nLinhAux2
		
		nsoma := 0
		
		cprebar := "9" + SubStr(AllTrim(SB1->B1_I_DUN14),2,(Len(AllTrim(SB1->B1_I_DUN14))-2))
		
		For _nI := 1 to Len(cprebar)
			
			If int(_nI/2) == _nI/2
				
				nsoma +=  Val(SubStr(cprebar,_nI,1))
				
			Else
				
				nsoma += 3 * Val(SubStr(cprebar,_nI,1))
				
			EndIf
			
		Next
		
		nprox := nsoma
		
		While int(nprox/10) != nprox/10
			
			nprox++
			
		EndDo
		
		cdigito := AllTrim(Str(nprox-nsoma))
		
		cgtin := cprebar + cdigito
		
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, cgtin, oFont10)//150
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, transform(Round((npeso - (ZFW->ZFW_TREMB+ZFW->ZFW_TRCAX)),2),"@E 9,999,999.99") + " kg.", oFont10) //aret[2]+aret[1]//750
		nLinha += 050
		
		oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
		nLinha += 010
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Data de Validade", oFont10n)//70
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, "Quantidade", oFont10n)//610

		oPrint:Line(nlinha - 10  , ncoluna + nLinMeio, nlinha + 110,  ncoluna + nLinMeio)
		
		nLinha += 060-nLinhAux2
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, DToC(dvalid), oFont10)//210
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, TRANSFORM(nquant,"@E 9,999,999"), oFont10)//750
		
		nLinha += 050
		oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
		nLinha += 010
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Lote", oFont10n)//170
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, "Data de Prod", oFont10n)//710
		oPrint:Line(nlinha - 10 , ncoluna + nLinMeio, nlinha + 110,  ncoluna + nLinMeio)
		
		nLinha += 060-nLinhAux2
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, clote, oFont10)//210
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, DToC(dprod), oFont10)//750
		
		nLinha += 050
		oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
		nLinha += 010
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "Peso Bruto", oFont10n)//120
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, "Produto"   , oFont10n)//710
		
		nLinha += 060-nLinhAux2
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, TRANSFORM(Round(npeso,2),"@E 9,999,999.99") + " kg.", oFont10)//110
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu2, SubStr(AllTrim(SB1->B1_DESC),1,30), oFont10)//510

		nLinha += 050

  		oPrint:Line(nlinha - 110 , ncoluna + nLinMeio, nlinha,  ncoluna + nLinMeio)//LINHA DO MEIO FINAL
		oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)                   // Imprime um Traco

		nLinha += 010
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "No. Registro Processador", oFont10n)//350
		
		nLinha += 060-nLinhAux2
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "0763763", oFont10)//370
		
		nLinha += 050
		oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)                    // Imprime um Traco
		nLinha += 010
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "SSCC - Código de Série da Unidade Logística", oFont10n)//220
		
		nLinha += 060-nLinhAux2
		
		//Monta pré string do SSCC para calcular dígito verificador - http://www.gs1.org/how-calculate-check-digit-manually
		
		If lreimprime
			
			csequen  := ZFW->ZFW_SEQUEN
			
		Else
			
			csequen := getsxenum("ZFW","ZFW_SEQUEN")
			
		EndIf
		
		cprebar := "0" + "789808064" + csequen
		
		nsoma := 0
		
		For _nI := 1 to Len(cprebar)
			If int(_nI/2) == _nI/2
				nsoma +=  Val(SubStr(cprebar,_nI,1))
			Else
				nsoma += 3 * Val(SubStr(cprebar,_nI,1))
			EndIf
		Next _nI
		
		nprox := nsoma
		
		While int(nprox/10) != nprox/10
			nprox++
		EndDo
		
		cdigito := AllTrim(Str(nprox-nsoma))
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nEsqu1, "0" + "789808064" + csequen + cdigito, oFont10)//350
		
	Else// ***************  LAYOUT FIXO  *********************************************************************
		
		//=========================== quadrado "GTIN"
		
		nsoma := 0
		
  		cprebar := "0" + SubStr(AllTrim(SB1->B1_I_DUN14),2,(Len(AllTrim(SB1->B1_I_DUN14))-2))//SubStr(AllTrim(SB1->B1_I_DUN14),1,13)//( Len(AllTrim(SB1->B1_I_DUN14))-1)

		If Len(cprebar) < 14
			
			For _nI := 1 to Len(cprebar)
				If int(_nI/2) == _nI/2
					nsoma +=  Val(SubStr(cprebar,_nI,1))
				Else
					nsoma += 3 * Val(SubStr(cprebar,_nI,1))
				EndIf
			Next _nI
			
			nprox := nsoma
			
			While int(nprox/10) != nprox/10
				nprox++
			EndDo
			
			cdigito := AllTrim(Str(nprox-nsoma))
		Else
			cdigito:=""
		EndIf
		
		cgtin := cprebar + cdigito
	
	    oPrint:Say(nLinha+nLinhAux1, nColuna+_nMeio, "GTIN", oFont10n,,,, 2)
		nLinha += 060
		
	    oPrint:Say(nLinha+nLinhAux1, nColuna+_nMeio, cgtin, oFont10,,,,2)
		nLinha += 050
		
		
		//===================================  quadrado "Data de Validade" + "Data de Validade"
		
		oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
		nLinha += 010
		
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeioE, "Data de Validade", oFont10n,,,,2)
	   oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeioD, "Data de Prod."   , oFont10n,,,,2)

		oPrint:Line(nlinha - 10 , ncoluna + nLinMeio, nlinha + 110,  ncoluna + nLinMeio)
		nLinha += 060
		
	    oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeioE, DToC(dvalid), oFont10,,,,2)
	    oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeioD, DToC(dprod) , oFont10,,,,2)
		nLinha += 050
		
		oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)
		nLinha += 010
		
		//===================================  quadrado lote + produto

        nLinhAux1:=35
		
	    oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeioE, "Lote"   , oFont10n,,,,2)
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeioD, "Produto", oFont10n,,,,2)
		
		nLinha += 060
		
	    oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeioE, clote , oFont10,,,,2)
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeioD, SubStr(AllTrim(SB1->B1_DESC),1,30), oFont10)
		
		
		nLinha += 050

  		oPrint:Line(nlinha - 120 , ncoluna + nLinMeio, nlinha,  ncoluna + nLinMeio)//LINHA DO MEIO FINAL
		oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)                    // Imprime um Traco

		nLinha += 010
		
		//=================================== quadrado No. Registro Processador"
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeio, "No. Registro Processador", oFont10n,,,,2)
		
		nLinha += 060
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeio, "0763763", oFont10,,,,2)
		nLinha += 050
		
		oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)                    // Imprime um Traco
		nLinha += 010
		
		//=================================== quadrado SSCC - Código de Série da Unidade Logística
		
		//Monta pré string do SSCC para calcular dígito verificador - http://www.gs1.org/how-calculate-check-digit-manually
		
		If lreimprime
			csequen  := ZFW->ZFW_SEQUEN
		Else
			csequen := getsxenum("ZFW","ZFW_SEQUEN")
		EndIf
		
		cprebar := "0" + "789808064" + csequen
		
		nsoma := 0
		
		For _nI := 1 to Len(cprebar)
			If int(_nI/2) == _nI/2
				nsoma +=  Val(SubStr(cprebar,_nI,1))
			Else
				nsoma += 3 * Val(SubStr(cprebar,_nI,1))
			EndIf
		Next _nI
		
		nprox := nsoma
		
		While int(nprox/10) != nprox/10
			nprox++
		EndDo
		
		cdigito := AllTrim(Str(nprox-nsoma))
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeio, "SSCC - Código de Série da Unidade Logística", oFont10n,,,,2)
		nLinha += 060
		
		oPrint:Say(nLinha+nLinhAux1, nColuna + _nMeio, "0" + "789808064" + csequen + cdigito, oFont10,,,,2)
		
	EndIf
	
	//=================================== quadrado taras
	
	nLinha += 050
	oPrint:Line(nlinha,ncoluna - 5,nlinha,ncoluna + ntamh)                    // Imprime um Traco
	
	oPrint:Say(nLinha+nLinhAux1, nColuna + 10, "Tara Embalagem:", oFont10n)
	oPrint:Say(nLinha+nLinhAux1, nColuna + 350, transform(Round(ZFW->ZFW_TREMB,3),"@E 9,999.999") + " kg", oFont10)
	nLinha += 060 - nLinhAux2
	
	oPrint:Say(nLinha+nLinhAux1, nColuna + 10, "Tara Caixa:", oFont10n)
	oPrint:Say(nLinha+nLinhAux1, nColuna + 350, transform(Round(ZFW->ZFW_TRCAX,3),"@E 9,999.999") + " kg", oFont10)
	nLinha += 060 - nLinhAux2
	
	oPrint:Say(nLinha+nLinhAux1, nColuna + 10, "Tara Total:", oFont10n)
	oPrint:Say(nLinha+nLinhAux1, nColuna + 350, transform(Round(ZFW->ZFW_TREMB+ZFW->ZFW_TRCAX,3),"@E 9,999.999") + " kg", oFont10)
	
	nLinha += 060
	
	//=================================== CODIGO DE BARRAS
	
	If _lLayoutVariavel // ***************   LAYOUT  VARIAVEL  ****************************
		
		ccodbar1 := "(01)" + cgtin + "(3102)" + StrZero(Round((npeso - (ZFW->ZFW_TREMB+ZFW->ZFW_TRCAX))*100,0),6)//aret[2]+aret[1]
		
		ccodbar1 += "(3302)" +  StrZero(Round(npeso*100,0),6) + "(30)" + AllTrim(Str(Round(nquant,0)))
		
		ccodbar2 := "(15)" + SubStr(DToS(dvalid),3,2) +  SubStr(DToS(dvalid),5,2) + SubStr(DToS(dvalid),7,2)
		//    					ano                        mes                           dia
		
		ccodbar2 += "(11)" +  SubStr(DToS(dprod),3,2) +  SubStr(DToS(dprod),5,2) + SubStr(DToS(dprod),7,2)
		//						ano                        mes                           dia
		
		ccodbar2 += "(7030)" + "0763763" 
		//                      Reg SIF
	   cCodBar2Say:=ccodbar2
       ccodbar2:=StrTran(ccodbar2,"(","")
       ccodbar2:=StrTran(ccodbar2,")","")
	   ccodbar2 += "(10)" + AllTrim(clote)
	   cCodBar2Say+= "(10)" + AllTrim(clote)
		
		ccodbar3 := "(00)0" + "789808064" + csequen + cdigito
		//                       Registro GS1
		
	Else// ***************  LAYOUT FIXO  ****************************
		
		ccodbar1 := "(01)" + cgtin + "(15)"  + SubStr(DToS(dvalid),3,2) +  SubStr(DToS(dvalid),5,2) + SubStr(DToS(dvalid),7,2)
		//    					                        ano                        mes                           dia
		
		ccodbar1 += "(11)" +  SubStr(DToS(dprod),3,2) +  SubStr(DToS(dprod),5,2) + SubStr(DToS(dprod),7,2)
		//    					ano                        mes                           dia
		
		ccodbar2 := "(7030)" + "0763763" //+ "(10)" + AllTrim(clote)
		//                      Reg SIF//      If _lSite
	    cCodBar2Say:=ccodbar2
        ccodbar2:=StrTran(ccodbar2,"(","")
        ccodbar2:=StrTran(ccodbar2,")","")
		ccodbar2 += "(10)" + AllTrim(clote)
	    cCodBar2Say+= "(10)" + AllTrim(clote)
		
		ccodbar3 := "(00)0" + "789808064" + csequen + cdigito
		//                       Registro GS1
		
	EndIf
	
	If _lSite

		ccodbar1:=StrTran(ccodbar1,"(","")
		ccodbar1:=StrTran(ccodbar1,")","")
		
		ccodbar3:=StrTran(ccodbar3,"(","")
		ccodbar3:=StrTran(ccodbar3,")","")
		
		_cExt     := ".gif"
		_EndHttp1 := "https://barcode.tec-it.com/barcode.ashx?data="
		_EndHttp2 := "&code=EANUCC128&multiplebarcodes=true&translate-esc=true&unit=Fit&dpi=96&imagetype=Gif&rotation=0&color=%23000000&bgcolor=%23ffffff&qunit=Mm&quiet=0"
		_cCaminho := cLocal
		
		url := _EndHttp1 + ccodbar1 + _EndHttp2
		Html  := HttpGet( Url )
		If Html <> nil
			MemoWrite( _cCaminho + ccodbar1 + _cExt, Html )
		EndIf
		oPrint:SayBitmap( nlinha - 05 ,ncoluna+40,_cCaminho + ccodbar1 + _cExt,1050,170 )
		
	Else
  
		cCodBar1Say:=ccodbar1
		ccodbar1:=StrTran(ccodbar1,"(","")
		ccodbar1:=StrTran(ccodbar1,")","")
		
		cCodBar3Say:=ccodbar3
		ccodbar3:=StrTran(ccodbar3,"(","")
		ccodbar3:=StrTran(ccodbar3,")","")

		_cTypeBar:="EAN128"//"CODE128"
		nlinha+=5
		
	EndIf
	
	nLinha += 180
	
	If _lSite

		url := _EndHttp1 + ccodbar2 + _EndHttp2 //+ "&code=EANUCC128&multiplebarcodes=false&translate-esc=true&unit=Fit&dpi=96&imagetype=Gif&rotation=0&color=%23000000&bgcolor=%23ffffff&qunit=Mm&quiet=0%27%20alt=%27Barcode%20Generator%20TEC-IT%27"//"&SHOW-TEXT=FALSE"
		Html  := HttpGet( Url )
		If Html <> nil
			MemoWrite( _cCaminho + ccodbar2 + _cExt, Html )
		EndIf
		oPrint:SayBitmap( nlinha + 55 ,ncoluna+40,_cCaminho + ccodbar2 + _cExt,1050,170 )
		
	Else
		
  	   oPrint:Say(nLinha-30, nColuna + 100, cCodBar1Say, oFont10)
		
		nlinha+=10
		
	EndIf

	nLinha += 245

	If _lSite
		
		url := _EndHttp1 + ccodbar3  + _EndHttp2//+ "&code=EANUCC128&multiplebarcodes=false&translate-esc=true&unit=Fit&dpi=96&imagetype=Gif&rotation=0&color=%23000000&bgcolor=%23ffffff&qunit=Mm&quiet=0%27%20alt=%27Barcode%20Generator%20TEC-IT%27"//"&SHOW-TEXT=FALSE"
		Html  := HttpGet( Url )
		If Html <> nil
			MemoWrite( _cCaminho + ccodbar3 + _cExt, Html )
		EndIf
		oPrint:SayBitmap( nlinha + 55 ,ncoluna+40,_cCaminho + ccodbar3 + _cExt,600,170 )
		
	Else
		
		oPrint:Say(nLinha-060, nColuna + 100, cCodBar2Say, oFont10)
		
		nlinha+=10
		
		If _lLayoutVariavel // ***************   LAYOUT  VARIAVEL  ****************************

			
//          oPrint:FWMsBar(_cTypeBar,nRow,nCol,cCode,oPrint,lCheck,Color,lHorz, nWidth,nHeigth,lBanner,cFont,cMode,lPrint,nPFWidth,nPFHeigth,lCmtr2Pix)
			oPrint:FWMSBAR(_cTypeBar,20,0.4,ccodbar1,oPrint,.T.,,.T.,0.0168,0.7,.F.,"Arial","C",.F.,1,1,.F.)
			
			oPrint:FWMSBAR(_cTypeBar,25,0.5,ccodbar2,oPrint,.T.,,.T.,0.0168,0.7,.F.,"Arial","C",.F.,1,1,.F.)
			
			oPrint:FWMSBAR(_cTypeBar,30,0.5,ccodbar3,oPrint,.T.,,.T.,0.0168,0.7,.F.,"Arial","C",.F.,1,1,.F.)
		Else

			oPrint:FWMSBAR(_cTypeBar,19,1,ccodbar1,oPrint,.T.,,.T.,0.0168,0.9,.F.,"Arial","C",.F.,1,1,.F.)
			
			oPrint:FWMSBAR(_cTypeBar,24,1,ccodbar2,oPrint,.T.,,.T.,0.0168,0.9,.F.,"Arial","C",.F.,1,1,.F.)
			
			oPrint:FWMSBAR(_cTypeBar,29,1,ccodbar3,oPrint,.T.,,.T.,0.0168,0.9,.F.,"Arial","C",.F.,1,1,.F.)
			
		EndIf
		
	EndIf
	//=================================== CODIGO DE BARRAS
	
	nLinha += 245

	If _lSite
		nLinha += 60
	Else

        oPrint:Say(nLinha-100, nColuna + 100, cCodBar3Say, oFont10)
        
		nLinha += 20

	EndIf

  	oPrint:Line(nlinhaIni,ncoluna - 5     , nlinha, ncoluna - 5     )//LINHA LATERAL ESQUERDA 
  	oPrint:Line(nlinhaIni,ncoluna + ntamh , nlinha, ncoluna + ntamh )//LINHA LATERAL DIRETA
	oPrint:Line(nlinha   ,ncoluna - 5     , nlinha ,ncoluna + ntamh )//LINHA FINAL
	
	oPrint:EndPage()                // Finaliza a Pagina de Impressao

Next

If _lSite
	
    LjMsgRun( "Gerando a visualização..." , "Aguarde!" , {|| oPrint:Preview() } )//Visualiza antes de imprimir
	oPrint:End()
	
Else
	
	If !(oPrint:nModalResult == PD_OK)
		oPrint:Deactivate() 
		Return
	EndIf
    LjMsgRun( "Gerando a visualização..." , "Aguarde!" , {|| oPrint:Preview() } )//Visualiza antes de imprimir

EndIf

Return nRecZFW

/*
===============================================================================================================================
Programa----------: ROMS046Fil
Autor-------------: Alex Wallauer
Data da Criacao---: 21/12/2017
===============================================================================================================================
Descrição---------: Get da filial da estrutura do produto
===============================================================================================================================
Parametros--------: cproduto: codigo do produto
===============================================================================================================================
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/  
Static Function ROMS046Fil(cproduto)
Local _lRet:=.T.,oDlgFil
Local _cFilsSG1:=""
Local _nCol1:=15
Local _nCol2:=90

If Empty(cproduto)
   Return .T.
EndIf

SG1->(DBSetOrder(1))
If SG1->(DBSeek(_cFilSG1+cproduto))
   Return .T.
EndIf

cquery := "SELECT G1_FILIAL FROM " + RETSQLNAME("SG1")
cquery += " WHERE D_E_L_E_T_ = ' ' AND G1_COD = '" + cproduto+"'"
cquery += " GROUP BY G1_FILIAL "

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'FilSG1', .T., .F.)
FilSG1->(DBGoTop())

While FilSG1->(!Eof())
   _cFilsSG1+=FilSG1->G1_FILIAL+", "
   FilSG1->(DBSkip())
EndDo

FilSG1->(DBCloseArea())
DBSelectArea("ZFW")

_cFilsSG1:=LEFT(_cFilsSG1,Len(_cFilsSG1)-2)

While .T.

   @ 000, 000 To 140, 300 Dialog oDlgFil Title "Produto "+AllTrim(cproduto)+If(Empty(_cFilsSG1)," NÃO possui estrutura","")
    
    If !Empty(_cFilsSG1)
    
	   @ 011, 015 Say "Filial da Estrutura do Produto" PIXEL
	   @ 010, 100 Get _cFilSG1 Picture "99"  Size 030, 010 F3 "SM0"
	   @ 023, 015 Say "Filiais com Estrutura desse Produto: "+_cFilsSG1 PIXEL

     Else

	   @ 005, _nCol1 Say "Tara Embalagem:" PIXEL
	   @ 005, _nCol2 Get _nTaraEmb Picture "@E 999.999"  Size 030, 010 VALID NaoVazio(_nTaraEmb) .And. Positivo(_nTaraEmb) PIXEL

	   @ 020, _nCol1 Say "Tara Caixa:" PIXEL
	   @ 020, _nCol2 Get _nTaraCx Picture "@E 999.999"  Size 030, 010 VALID NaoVazio(_nTaraCx) .And. Positivo(_nTaraCx) PIXEL

    EndIf

	@ 040, 030 BmpButton Type 1 Action ( _lRet := .T. ,  Close(oDlgFil))
	@ 040, 100 BmpButton Type 2 Action ( _lRet := .F. ,  Close(oDlgFil))

   Activate Dialog oDlgFil Centered

   If _lRet
      If !Empty(_cFilsSG1)
         SG1->(DBSetOrder(1))
         If Empty(_cFilSG1) .Or. !SG1->(DBSeek(_cFilSG1+cproduto))
            U_ITMsg("Não existe estrutura desse produto na filial informada","Atenção","Selecione uma da(s) filiais ("+_cFilsSG1+") que possua estrutura para esse produto: "+cproduto,1)
            Loop
         EndIf
      Else
         If !( NaoVazio(_nTaraEmb) .And. Positivo(_nTaraEmb) .And. NaoVazio(_nTaraCx) .And. Positivo(_nTaraCx) )
            Loop
         ElseIf _nTaraEmb+_nTaraEmb >= npeso
            U_ITMsg("A soma das Taras não podem ser maior que o peso Bruto","Atenção","Digite valores cujo a soma ser menor que "+TRANSFORM(Round(npeso,2),"@E 9,999,999.99")+" kg.",1)
            Loop
         EndIf
      EndIf
   EndIf                             

   Exit
   
EndDo

Return _lRet


/*
===============================================================================================================================
Programa----------: ROMS046Tot
Autor-------------: Alex Wallauer
Data da Criacao---: 21/12/2017
===============================================================================================================================
Descrição---------: calcula a qtde de caixa
===============================================================================================================================
Parametros--------: cproduto: codigo do produto ; _cCalc: decide o retorno ; nquant: QUANTIDADE dentro da caixa
===============================================================================================================================
Retorno-----------: Retorna Total de caixas do produto ou a quantidade na caixa e preenche a nquant _nPesDigCaixa
===============================================================================================================================
*/  
Static Function ROMS046Tot(cproduto,_cCalc,nquant)
Local _nTotSB1:=0,_nPesPac,_n1Kg

SB1->(DBSetOrder(1))
If SB1->(DBSeek(xFilial("SB1")+cproduto))
	If _cCalc == "QTDE"

       If SB1->B1_UM = "KG" .And. SB1->B1_SEGUM = "CX"

          ZA2->(DBSetOrder(1))
          If !ZA2->(DBSeek(xFilial()+SB1->B1_I_NIV3)) .Or. !"G" $ Upper(ZA2->ZA2_DESCRI)
             Return 0
          EndIf
          _nPesPac:=Val(AllTrim(ZA2->ZA2_DESCRI))
          _n1Kg   :=(1000/_nPesPac)//qtde de pacotinhos em 1 KG
          _nQtePacCX   := _n1Kg * SB1->B1_CONV//qtde de pacotinhos em 1 caixa
          nquant:=If(nquant>0,nquant,_nQtePacCX)
          _nPesDigCaixa:= nquant * (_nPesPac/1000) //Peso do pacotes digitados

          Return _nQtePacCX//Qtde na caixa para produto fixo

       ElseIf SB1->B1_UM = "KG"  .And. SB1->B1_I_3UM = "CX"

          Return SB1->B1_I_QT3UM//Qtde na caixa para produto vairavel

       ElseIf SB1->B1_UM = "UN" .And. SB1->B1_SEGUM = "CX"

          Return SB1->B1_CONV //Qtde na caixa para produto fixo

       Else

          Return 0

       EndIf  

	Else

		If SB1->B1_I_UMPAL <> SB1->B1_I_QTOC3 .And. !Empty(SB1->B1_I_QTOC3)

			_nTotSB1:=(SB1->B1_I_CXPAL / SB1->B1_I_QT3UM)

		Else

			_nTotSB1:=SB1->B1_I_CXPAL

		EndIf

	EndIf
	
EndIf

Return _nTotSB1

/*
===============================================================================================================================
Programa----------: ROMS046Caixa
Autor-------------: Alex Wallauer
Data da Criacao---: 22/12/2017
===============================================================================================================================
Descrição---------: Verifica número de caixa do novo registro
===============================================================================================================================
Parametros--------: _lValida:  .T. ou .F.
===============================================================================================================================
Retorno-----------: string com número da caixa
===============================================================================================================================*/  

Static Function ROMS046Caixa(_lValida)

Local _xCaixa   := ""
Local cquery    := ""
Local _nQtePacCX:=0

cquery := "SELECT ZFW_CAIXA, COUNT(ZFW_CAIXA) QTDE,"
cquery += " SUM(ZFW_QUANT) QUANT"
cquery += " FROM " + retsqlname("ZFW") + " WHERE D_E_L_E_T_ = ' ' AND ZFW_FILIAL = '" + xFilial("ZFW") +"'" 
cquery += " AND ZFW_PRODUT = '" + cproduto + "' AND ZFW_TIPO = 'C'" 
If _lValida
   cquery += " AND ZFW_CAIXA = '" + _cCaixa + "'" 
   _xCaixa:=.T.
EndIf
cquery += " GROUP BY ZFW_CAIXA ORDER BY ZFW_CAIXA "

DBUSEAREA(.T., "TOPCONN", TCGENQRY(,,CQUERY), 'TSD1', .T., .F.)

_nQtePacCX:=ROMS046Tot(cproduto,"QTDE",nquant)

While !TSD1->(Eof())
    
	If _lValida
  	   _nTotC:=(TSD1->QUANT+nquant)
  	   _xCaixa:=.T.
    Else
  	   _nTotC:=TSD1->QUANT  	   
    EndIf
	If !_lValida .And. _nTotC < _nQtePacCX//Procura CAIXA incompleto
       _xCaixa := TSD1->ZFW_CAIXA
       Exit
	ElseIf _lValida .And. _nTotC > _nQtePacCX
       U_ITMsg("Essa caixa já tem "+AllTrim(Str(TSD1->QUANT))+" unidades" ,"Atenção","Digite no maximo mais "+AllTrim(Str(_nQtePacCX-TSD1->QUANT))+" pacote(s).",1)
       TSD1->(DBCloseArea())
       Return .F.
	EndIf

	TSD1->(DBSkip())
		
EndDo

TSD1->(DBCloseArea())

//Se não achou caixa incompleto faz um novo pallet
If Empty(_xCaixa) .And. !_lValida

	cquery := "SELECT MAX(ZFW_CAIXA) NUM FROM " + RETSQLNAME("ZFW") + " WHERE D_E_L_E_T_ = ' ' AND ZFW_FILIAL = '" + xFilial("ZFW") +"'"   

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'TSD1', .T., .F.)

	If TSD1->(Eof()) 
		_xCaixa := StrZero(1,Len(ZFW->ZFW_CAIXA))
	Else
		_xCaixa := StrZero(Val(TSD1->NUM)+1,Len(ZFW->ZFW_CAIXA))
	EndIf
	
	TSD1->(DBCloseArea())
	
EndIf

Return _xCaixa
