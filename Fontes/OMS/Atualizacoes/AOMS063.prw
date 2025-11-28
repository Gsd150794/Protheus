/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 06/11/2018 | Validação planilha importação de metas de vendas - Chamado 26886
 Julio Paz        | 04/02/2019 | Correções de erro log com a utilização da função GDDeleted(). Chamado 27917.
 Lucas Borges     | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
========================================================================================================================================================================
Analista    - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
========================================================================================================================================================================
Andre       - Alex Wallauer - 09/05/25 - 31/07/25 - 50460   - Ajsutes para o novo layout de integração de dados dos vendedores via CSV.
Vanderlei   - Alex Wallauer - 03/10/25 - 07/10/25 - 52365   - Retirado o travamento na importação de metas quando o vendedor/produto está bloqueado.
Vanderlei   - Alex Wallauer - 09/10/25 - 13/10/25 - 52365   - Somatoria das quantidades e valores das linhas duplicadas Vendedor/Coordenador+Produto.
==============================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "RWMAKE.CH"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS063
Autor-------------: Erich Buttner
Data da Criacao---: 11/04/2013
Descrição---------: Cadastro de Metas de Vendas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS063()
 Local _bBotaoImp  As CodeBlock
 Local _bBotaoExc  As CodeBlock
 Local _bBotaoI    As CodeBlock
 Local _bBotaoY    As CodeBlock
 Local _bBotaoC    As CodeBlock
 Local _bBotaoZ    As CodeBlock
 Local _bBotaoG    As CodeBlock
 Local _aParAux    := {} As Array
 Local _aParRet    := {} As Array
 Local nI          := 0 As Numeric
 Local nLinha      := 0 As Numeric
 Local nCol1       := 0 As Numeric
 Local nColB       := 0 As Numeric
 Local nLar1       := 0 As Numeric
 Local nAlt1       := 0 As Numeric
 Local nAlt2       := 0 As Numeric
 Private aCpoBrw   := {} As Array
 Private aCpoTmp   := {} As Array
 Private cArq      := "" As Char
 Private cPesq     := Space(50) As Char
 Private lCheck1   := .T. As Logical
 Private lCheck2   := .T. As Logical
 Private lCheck3   := .T. As Logical
 Private _cOrdem   := "Ano+Mes+Nome" As Char
 Private aOrdem	   := {"Ano+Mes+Nome","Coord./Vend.+Ano+Mes","Nome Coord./Vend."} As Array
 Private cPesquisa := Space(200) As Char
 Private cAnoMes   := "" As Char
 Private cCoord    := "" As Char
 Private cTipoor   := "" As Char
 Private _cUserName:= UsrFullName(RetCodUsr()) As Char
 Private _nLB      := 20 As Numeric
 Private _nMSS     := 24 As Numeric
 Private cChama    := "RECARREGA" As Char
 Private aSize     := {} As Array
 Private aObjects  := {} As Array
 Private aInfo     := {} As Array
 Private aPosObj   := {} As Array
 Private _cAnoIni  := LEFT(DToS(dDataBase),6) As Char
 Private _cAnoFim  := LEFT(DToS(dDataBase),6) As Char
 Private oPesquisa As Object
 Private _oTemp    As Object
 Private oDlgLib   As Object
 Private oMark     As Object
 Private lGravouDados:=.F. As Logical

 MV_PAR01:=LEFT(DToS(dDataBase),6)
 MV_PAR02:=LEFT(DToS(dDataBase),6)

 AAdd( _aParAux , { 1 , "Ano-Mes Inicial:", MV_PAR01, "@R 9999-99","","","", 060 , .T. } )
 AAdd( _aParAux , { 1 , "Ano-Mes Final:"  , MV_PAR02, "@R 9999-99","","","", 060 , .F. } )

 For nI := 1 To Len( _aParAux )
    AAdd( _aParRet , _aParAux[nI][03] )
 Next nI

 If !ParamBox( _aParAux , "Intervalo de Anos da Meta de Vendedores/Coordenadores" , @_aParRet, {|| .T. } )
    Return .F.
 EndIf

 _cAnoIni:=Left(AllTrim(MV_PAR01)+"000000",6)
 _cAnoFim:=Left(AllTrim(MV_PAR02)+"999999",6)

 If !Empty(MV_PAR02) .And. _cAnoIni > _cAnoFim
  	U_ITMsg("Intervalo de Anos invalido.","Ano inicial dever ser menor ou igual ao ano final.",3)
    Return .F.
 EndIf

 _cAnoIni:=AllTrim(MV_PAR01)
 _cAnoFim:=AllTrim(MV_PAR02)

 _bBotaoImp:= {|| FWMsgRun( ,{|oProc| AOMS063K(oProc) } , TIME()+" - Processando..." , "Iniciando o processamento..." ) }
 _bBotaoExc:= {|| FWMsgRun( ,{|oProc| AOMS063N(oProc) } , TIME()+" - Processando..." , "Iniciando o processamento..." ) }
 _bBotaoY  := {|| FWMsgRun( ,{|oProc| AOMS063Y(oProc) } , TIME()+" - Processando..." , "Iniciando o processamento..." ) }
 _bBotaoI  := {|| FWMsgRun( ,{|oProc| AOMS063IM(oProc)} , TIME()+" - Processando..." , "Iniciando o processamento..." ) }
 _bBotaoC  := {|| FWMsgRun( ,{|oProc| AOMS063C(oProc) } , TIME()+" - Processando..." , "Iniciando o processamento..." ) }
 _bBotaoZ  := {|| FWMsgRun( ,{|oProc| AOMS063Z(oProc) } , TIME()+" - Processando..." , "Iniciando o processamento..." ) }
 _bBotaoG  := {|| FWMsgRun( ,{|oProc| AOMS063G(oProc) } , TIME()+" - Processando..." , "Iniciando o processamento..." ) }

 //Prepara variaveis de tamanho de tela aSize,aObjects,aInfo,aPosObj
 // Obtém a a área de trabalho e tamanho da dialog
 aSize := MsAdvSize()
 AAdd( aObjects, { 000, 000, .T., .T. } ) // Dados da Enchoice
 AAdd( aObjects, { 000, 000, .T., .T. } ) // Dados da getdados
 // Dados da área de trabalho e separação
 aInfo 	:= { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 } // Chama MsObjSize e recebe Array e tamanhos
 aPosObj := MsObjSize( aInfo, aObjects,.T.)

 While cChama != "SAIR"

    nLinha:=15
    nCol1:=13
    nColB:=05
    nLar1:=75
    nAlt1:=15
    nAlt2:=15

    If cChama = "RECARREGA"
       FWMsgRun( ,{|oProc| AOMS063U(oProc) }, 'Aguarde!' , 'Carregando os dados...'  ) //CARREGA O aCols
    EndIf

    cChama := "SAIR"
    DEFINE MSDIALOG oDlgLib FROM aSize[7],000 TO aSize[6],aSize[5] PIXEL TITLE " Metas de Vendas "

    oMark:=MsSelect():New("TMP","",,aCpoBrw,.T.,"XX",{040,005,aSize[4]-_nMSS,aSize[3]},,,,,)
    oMark:oBrowse:lHasMark := .T.
    oMark:oBrowse:lCanAllMark:=.T.

    @ 003,006 To 034,315 Title " Metas / Ordem "

    @ nLinha,nCol1 ComboBox _cOrdem ITEMS aOrdem Size nLar1,nAlt1 Object oOrdem
    @ nLinha,090   Get      cPesquisa            Size 00200,nAlt2 Object oPesquisa
    oOrdem:bChange := {|| AOMS063FO(_cOrdem),oMark:oBrowse:Refresh(.T.)}

    @ 015,330 Button "Pesquisar"       	    Size 55,13 Action AOMS063PC(_cOrdem) Object oBotao1
    @ 015,390 Button "Log"                  Size 55,13 Action AOMS063R(.T.)      Object oBotao2
    @ 015,450 Button "Manutenção % diario"  Size 80,13 Action AOMS063MD()        Object oBotao3

    //@ aSize[4]-_nLB,nColB Button "Exportar" Size 40,13 Action AOMS063E()// NÃO TEM MAIS POR ENQUANTO SEGUNDO VANDERLEI
    @ aSize[4]-_nLB,nColB Button "Importar"   Size 40,13 Action Eval(_bBotaoImp) Object oBotao3//AOMS063K( )
    nColB+=045
    @ aSize[4]-_nLB,nColB Button "Visualizar" Size 40,13 Action Eval(_bBotaoY)   Object oBotao4//AOMS063Y( )
    nColB+=045
    @ aSize[4]-_nLB,nColB Button "Incluir"    Size 40,13 Action Eval(_bBotaoI)   Object oBotao5//AOMS063IM( )
    nColB+=045
    @ aSize[4]-_nLB,nColB Button "Alterar"    Size 40,13 Action Eval(_bBotaoG)   Object oBotao8//AOMS063G( )
    nColB+=045
    @ aSize[4]-_nLB,nColB Button "Excluir"    Size 40,13 Action Eval(_bBotaoExc) Object oBotao9//AOMS063N( )
    nColB+=045
    @ aSize[4]-_nLB,nColB Button "Copiar"     Size 40,13 Action Eval(_bBotaoC)   Object oBotao6//AOMS063C( )
    nColB+=045
    @ aSize[4]-_nLB,nColB Button "Replicar"   Size 40,13 Action Eval(_bBotaoZ)   Object oBotao7//AOMS063Z( )
    nColB+=045
    @ aSize[4]-_nLB,nColB Button "Relatorio"  Size 40,13 Action AOMS063R(.F.)    Object oBotaoR
    nColB+=045
    @ aSize[4]-_nLB,nColB Button "Sair"       Size 40,13 Action (cChama:="SAIR",oDlgLIb:End()) Object oBotaoS

    ACTIVATE DIALOG oDlgLib CENTERED

    //Grava Log de execução da rotina
    U_ITLOGACS()

 EndDo

 If Select("TMP") > 0 .And. Type("_oTemp") == "O"
    _oTemp:Delete()
 EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS063PC
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Pesquisa Informações no Browse de acordo com a Ordem selecionada
Parametros--------: _cOrdem - indice a ser usado
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063PC(_cOrdem As Char)
 TMP->( DBSetOrder(AScan(aOrdem,_cOrdem)) )
 TMP->( DBGoTop() )
 TMP->( MSSeek(AllTrim(cPesquisa),.T.) )
 oMark:oBrowse:Refresh(.T.)
Return

/*
===============================================================================================================================
Programa----------: AOMS063PC
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Funcao executada na saida do campo Ordem, para ordenar o browse
Parametros--------: _cOrdem - indice a ser usado
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063FO(_cOrdem As Char)
 cPesquisa:=Space(200)
 oPesquisa:Refresh()
 TMP->(DBSetOrder(AScan(aOrdem,_cOrdem)))
 TMP->(DBGoTop())
 oMark:oBrowse:Refresh(.T.)
Return

/*
===============================================================================================================================
Programa----------: AOMS063IM
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: INCLUSÃO DE METAS DE VENDAS
Parametros--------: oProc - Objeto de processo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063IM(oProc As Object)

 Local cTitulo    := "Inclusão de Metas de Vendas" As Char
 Local lRetMod2   :=.F. As Logical // Retorno da função Modelo2 - .T. Confirmou / .F. Cancelou
 Local aYesFields := {} As Array
 Local aCGD       := {} As Array
 Local ACORDW     := {} As Array
 Local _l         := 00 As Numeric
 Private nOpcx    := 03 As Numeric

 nUsado:=0
 aHeader:={}
 aCols:={}

 //Carrega aheader
 aYesFields := {"ZZS_COD","ZZS_DESCR","ZZS_DESCD","ZZS_QTD","ZZS_UM","ZZS_QTD2UM","ZZS_2UM","ZZS_QTD3UM","ZZS_3UM","ZZS_VALOR"}
 FillGetDados(2,"ZZS",1,,,,, aYesFields ,,,, .T. ,,,,,, )

 //Limpa dois ultimos campos do aheader
 asize(aheader,Len(aheader)-2)

 cAnoMes:= Space(06)
 cCoord := Space(06)
 cNmCoor:= Space(60)
 cTipoor:= Space(25)

 aC:={}
 // aC[n,1] = Nome da Variavel Ex.:"cCliente"
 // aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
 // aC[n,3] = Titulo do Campo
 // aC[n,4] = Picture
 // aC[n,5] = Validacao
 // aC[n,6] = F3
 // aC[n,7] = Se campo e' editavel .T. se nao .F.

 //"Inclusão de Metas de Vendas"
 AAdd(aC,{"cAnoMes",{15,003}," Ano-Mes ","@R 9999-99",,,.T.})
 AAdd(aC,{"cCoord" ,{15,080}," Codigo " ,"@!","U_AOMS063V('CCOORD') .And. (ExistCPO('SA3'))","SA3",.T.})
 AAdd(aC,{"cNmCoor",{15,155}," Nome "   ,"@!",,,.F.})
 AAdd(aC,{"cTipoor",{30,003}," Tipo "   ,"@!",,,.F.})

 // Array com descricao dos campos do Rodape do Modelo 2
 aR:={}
 // aR[n,1] = Nome da Variavel Ex.:"cCliente"
 // aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
 // aR[n,3] = Titulo do Campo
 // aR[n,4] = Picture
 // aR[n,5] = Validacao
 // aR[n,6] = F3
 // aR[n,7] = Se campo e' editavel .T. se nao .F.

 aButtons := {}
 AAdd(aButtons,{"",{||U_AOMS063D(cAnoMes,cCoord)},"Importação Produtos","Importação Produtos"})

 // Array com coordenadas da GetDados no modelo2
 aCGD:={60,06,26,74}
 ACORDW  := {ASIZE[7],0,ASIZE[6],ASIZE[5]}

 cLinhaOk:="U_AOMS063O()"
 cTudoOk :="U_AOMS063Z(.T.)"//"INCLUSÃO DE METAS DE VENDAS"

 // Chamada da Modelo2
 // lRetMod2 = .T. se confirmou
 // lRetMod2 = .F. se cancelou
 //                cTitulo [ aC ] [ aR ] [ aGd ] [ nOp ] [ cLinhaOk ] [ cTudoOk ]aGetsD [ bF4 ] [ cIniCpos ] [ nMax ] [ aCordW ] [lDelGetD ] [lMaximazed ] [ aButtons ]
 lRetMod2:=Modelo2(cTitulo,aC	,  aR	, aCGD	,nOpcx	,  cLinhaOk	,  cTudoOk ,	  ,		  ,		   		,  9999	,   ACORDW ,            ,    .T.      , aButtons  )

 cChama := "NÃO RECARREGAR" //Se Cancelou

 If lRetMod2 // Gravacao. . .
     lGravouDados:=.T.

     nPosProd:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'} )
     nPosDesc:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCR'} )
     nPosDesD:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCD'} )
     nPosUM	 := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_UM'} )
     nPosQtd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD'} )
     nPos2UM := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_2UM'} )
     nPos2Qtd:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD2UM'} )
     nPos3UM := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_3UM'   } )//Novo
     nPos3Qtd:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'} )//Novo
     nPosVal := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_VALOR' } )//Novo

     _cReg:=AllTrim(Str(Len(aCols)))
     _nCont:=0

     For _l := 1 To Len(aCols)

         _nCont++
         oProc:cCaption := ( "Incluindo Metas: " + StrZero(_nCont,5) + " de " + _cReg)
         ProcessMessages()

         If ! Atail(aCols[_l])

             ZZS->(RecLock("ZZS",.T.))//INCLUSAO1
             ZZS->ZZS_FILIAL	:= FWxfilial("ZZS")
             ZZS->ZZS_COD	:= aCols [_l,nPosProd]
             ZZS->ZZS_DESCR	:= aCols [_l,nPosDesc]
             ZZS->ZZS_DESCD	:= aCols [_l,nPosDesD]
             ZZS->ZZS_UM		:= aCols [_l,nPosUM]
             ZZS->ZZS_QTD   	:= aCols [_l,nPosQtd]
             ZZS->ZZS_2UM	:= aCols [_l,nPos2UM]
             ZZS->ZZS_QTD2UM	:= aCols [_l,nPos2Qtd]
             ZZS->ZZS_3UM	:= aCols [_l,nPos3UM] //Novo
             ZZS->ZZS_QTD3UM	:= aCols [_l,nPos3Qtd]//Novo
             ZZS->ZZS_VALOR  := aCols [_l,nPosVal] //Novo
             ZZS->ZZS_TIPOV  := Posicione("SA3",1,FWxfilial("SA3")+cCoord,"A3_I_TIPV")//Novo
             ZZS->ZZS_COOR	:= cCoord
             ZZS->ZZS_NMCOOR	:= cNmCoor
             ZZS->ZZS_ANOMES	:= cAnoMes
             ZZS->(MSUnLock())

             ZGW->(RecLock("ZGW",.T.))//INCLUSAO1
             ZGW->ZGW_FILIAL	:= FWxfilial("ZGW")
             ZGW->ZGW_COD	:= aCols[_l,nPosProd]
             ZGW->ZGW_DESCR	:= aCols[_l,nPosDesc]
             ZGW->ZGW_DESCD	:= aCols[_l,nPosDesD]
             ZGW->ZGW_UM		:= aCols[_l,nPosUM]
             ZGW->ZGW_QTD   	:= aCols[_l,nPosQtd]
             ZGW->ZGW_2UM	:= aCols[_l,nPos2UM]
             ZGW->ZGW_QTD2UM	:= aCols[_l,nPos2Qtd]
             ZGW->ZGW_3UM	:= aCols[_l,nPos3UM] //Novo
             ZGW->ZGW_QTD3UM	:= aCols[_l,nPos3Qtd]//Novo
             ZGW->ZGW_VALOR	:= ZZS->ZZS_VALOR    //Novo
             ZGW->ZGW_TIPOV	:= ZZS->ZZS_TIPOV    //Novo
             ZGW->ZGW_DATAM  := ZZS->ZZS_DATA     //Novo
             ZGW->ZGW_COOR	:= cCoord
             ZGW->ZGW_NMCOOR	:= cNmCoor
             ZGW->ZGW_ANOMES	:= cAnoMes
             ZGW->ZGW_OPER   := "INCLUSAO1"
             ZGW->ZGW_USER   := _cUserName
             ZGW->ZGW_DATA   := Date()
             ZGW->ZGW_HORA   := Time()
             ZGW->(MSUnLock())

             AOMS063Ger("GERAR_VALORES_POR_DATA",ZZS->ZZS_ANOMES)

         EndIf

     Next _l

     U_ITMsg("Inclusão gravada com sucesso","Atenção",,2)

     cChama = "RECARREGA"
     oDlgLIb:End()

 EndIf



Return


/*
===============================================================================================================================
Programa----------: AOMS063W
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Importação de Produtos para Inclusão
Parametros--------: nPorc - Porcentagem de reajuste dos precos ,oProc - Objeto de processo
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS063W(nPorc As Numeric,oProc As Object)

 Local cPrd   := "" As Char
 Local _cAlias:= GetNextAlias() As Char
 Local aItens := {} As Array
 Local nY:=nX := 0  As Numeric
 Local nPosProd:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'   } ) As Numeric
 Local nPosDesc:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCR' } ) As Numeric
 Local nPosDesD:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCD' } ) As Numeric
 Local nPosUM  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_UM'    } ) As Numeric
 Local nPosQtd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD'   } ) As Numeric
 Local nPos2UM := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_2UM'   } ) As Numeric
 Local nPos2Qtd:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD2UM'} ) As Numeric
 Local nPos3UM := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_3UM'   } ) As Numeric//Novo
 Local nPos3Qtd:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'} ) As Numeric//Novo

 oProc:cCaption := ( "Lendo Dados..." )
 ProcessMessages()

 cPrd := " SELECT D2_COD PRODUTO, B1_DESC DESCR, B1_I_DESCD DESCRDET,"
 cPrd += " Round((SUM(D2_QUANT  )/3)+((SUM(D2_QUANT  )/3)* '"+AllTrim(Str(nPorc))+ "'),2) QTDMEDIA1UM, "
 cPrd += " Round((SUM(D2_QTSEGUM)/3)+((SUM(D2_QTSEGUM)/3)* '"+AllTrim(Str(nPorc))+ "'),2) QTDMEDIA2UM,"
 cPrd += " D2_UM UM, D2_SEGUM SEGUM "
 cPrd += " FROM SD2010 SD2, SF2010 SF2, SB1010 SB1 "
 cPrd += " WHERE SF2.F2_EMISSAO > '"+DToS(DATE()-90)+"' "
 cPrd += " AND SF2.D_E_L_E_T_ = ' ' "
 cPrd += " AND SD2.D_E_L_E_T_ = ' ' "
 cPrd += " AND SB1.D_E_L_E_T_ = ' ' "
 cPrd += " AND SB1.B1_FILIAL = ' ' "
 cPrd += " AND SD2.D2_COD = SB1.B1_COD "
 cPrd += " AND SD2.D2_FILIAL = SF2.F2_FILIAL "
 cPrd += " AND SD2.D2_DOC = SF2.F2_DOC "
 cPrd += " AND SD2.D2_SERIE = SF2.F2_SERIE "
 cPrd += " AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
 cPrd += " AND SD2.D2_LOJA = SF2.F2_LOJA "
 cPrd += " AND SF2.F2_FORMUL = ' ' "
 cPrd += " AND SF2.F2_TIPO = 'N' "
 cPrd += " AND (SF2.F2_VEND2 = '"+AllTrim(cCoord)+"' OR SF2.F2_VEND1 = '"+AllTrim(cCoord)+"') "
 cPrd += " AND SB1.B1_TIPO = 'PA' "
 cPrd += " AND SB1.B1_MSBLQL = '2' "
 cPrd += " GROUP BY D2_COD,B1_DESC, B1_I_DESCD, D2_UM, D2_SEGUM "
 cPrd += " ORDER BY D2_COD "

 // Monta Area de Trabalho executando a Query
 MPSysOpenQuery( cPrd , _cAlias)

 aCols:={}

 While (_cAlias)->(!Eof())

    cProd   := (_cAlias)->PRODUTO
    cDescr  := (_cAlias)->DESCR
    cDescrD := (_cAlias)->DESCRDET
    cUM		:= (_cAlias)->UM
    nQtd	:= (_cAlias)->QTDMEDIA1UM
    c2UM	:= (_cAlias)->SEGUM
    nQtd2um	:= (_cAlias)->QTDMEDIA2UM
    AAdd(aItens,{cProd,cDescr,cDescrD,cUM,nQtd,c2UM,nQtd2um})
    (_cAlias)->(DBSkip())

 EndDo

 _cReg:=AllTrim(Str(Len(aItens)))
 _nCont:=0

 For nX:= 1 TO Len(aItens)

     _nCont++
     oProc:cCaption := ( "Lendo Item: " + StrZero(_nCont,5) + " de " + _cReg)
     ProcessMessages()

     AAdd(aCols,Array(Len(aHeader)+1))
     For nY	:= 1 To Len(aHeader)
         aCols[Len(aCols)][nY] := CriaVar(aHeader[nY][2])
     Next nY

     N := Len(aCols)
     aCols[N][Len(aCols[N])] := .F.

     aCols [N,nPosProd]:= aItens[nX][1]
     aCols [N,nPosDesc]:= Posicione("SB1",1,FWxfilial("SB1")+aItens[nX][1],"B1_DESC")
     aCols [N,nPosDesD]:= SB1->B1_I_DESCD
     aCols [N,nPosUM]  := SB1->B1_UM
     aCols [N,nPosQtd] := aItens[nX][5]
     aCols [N,nPos2UM] := SB1->B1_SEGUM
     aCols [N,nPos2Qtd]:= aItens[nX][7]
     aCols [N,nPos3UM] := SB1->B1_I_3UM
     If !Empty(SB1->B1_I_QT3UM)
        aCols [N,nPos3Qtd]:= (aItens[nX][5] / SB1->B1_I_QT3UM )
     EndIf

 Next nX
 (_cAlias)->(DBCloseArea())
 xObj := CallMod2Obj()
 xObj:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS063O
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: VALIDA LINHA DO aCols
Parametros--------: Nenhum
Retorno-----------: _lRet - .T. se ok / .F. se erro
===============================================================================================================================
*/
User Function AOMS063O() As Logical
 Local nPosQtd  := 0 As Numeric
 Local nPos2Qtd := 0 As Numeric
 Local nPosDesc := 0 As Numeric
 Local nPosDesD := 0 As Numeric
 Local nPosUM   := 0 As Numeric
 Local nPos2UM  := 0 As Numeric
 Local nPos3UM  := 0 As Numeric//Novo
 Local nPos3Qtd := 0 As Numeric//Novo
 Local nPosVal  := 0 As Numeric//Novo
 Local nQtd     := 0 As Numeric
 Local nQtd2UM  := 0 As Numeric
 Local nQtd3UM  := 0 As Numeric//Novo
 Local nPosProd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'} ) As Numeric
 Local xObj     := CallMod2Obj() As Object
 Local N        := xObj:oBrowse:nat As Numeric
 Local cProd    := aCols[N,nPosProd] As Char
 Local cbloq    := Posicione("SB1",1,FWxfilial("SB1")+cProd,"B1_MSBLQL") As Char
 Local _lRet    := .T. As Logical

 If Atail(aCols[N])
    Return .T.
 EndIf

 If (Empty(AllTrim(cProd)) .Or. Empty(SB1->B1_COD))
    U_ITMsg("Escolha um Produto Valido.","Atenção",,1)
    _lRet	:= .F.
 EndIf

 If cbloq == '1'
    U_ITMsg("Produto Bloqueado","Atenção",,1)
    _lRet	:= .F.
 EndIf

 If _lRet

    nPosQtd  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD'   } )
    nPosDesc := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCR' } )
    nPosDesD := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCD' } )
    nPosUM	 := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_UM'    } )
    nPos2UM	 := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_2UM'   } )
    nPos2Qtd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD2UM'} )
    nPos3UM  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_3UM'   } )//Novo
    nPos3Qtd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'} )//Novo
    nPosVal  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_VALOR' } )//Novo

    aCols[N,nPosDesc] := SB1->B1_DESC
    aCols[N,nPosDesD] := SB1->B1_I_DESCD
    aCols[N,nPosUM  ] := SB1->B1_UM
    aCols[N,nPos2UM ] := SB1->B1_SEGUM
    aCols[N,nPos3UM ] := SB1->B1_I_3UM //Novo

    nQtd	:= aCols [n,nPosQtd ]
    nQtd2UM := aCols [n,nPos2Qtd]
    nQtd3UM := aCols [n,nPos3Qtd] //Novo

    If nQtd <= 0 .Or. nQtd2UM <= 0 .And. nQtd3UM < 0
        U_ITMsg("Quantidade(s) com o conteudo invalido.","Atenção","Preencha As Quantidades da 1a e 2a e/ou 3a unidades com valor positivo.",1)
        _lRet	:= .F.
    EndIf

    If aCols [N,nPosVal] <= 0
        U_ITMsg("Campo Valor (R$) com conteudo invalido.","Atenção","Preencha o valor com um numero positivo.",1)
        _lRet	:= .F.
    EndIf

 EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS063Z
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Validação geral das telas de inclusão e alteração
Parametros--------: _lInclui - .T. se inclusão / .F. se alteração
Retorno-----------: _lRet - .T. se ok / .F. se erro
===============================================================================================================================
*/
User Function AOMS063Z(_lInclui As Logical) As Logical
 Local X       := 000 As Numeric
 Local _cErro  := " " As Char
 Local _aErros := { } As Array
 Local _lRet   := .T. As Logical
 Local nPosProd:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'   } ) As Numeric
 Local nPosVal := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_VALOR' } ) As Numeric
 Local nPosQtd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD'   } ) As Numeric //Novo
 Local nPos2Qtd:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD2UM'} ) As Numeric //Novo
 Local nPos3Qtd:= AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'} ) As Numeric //Novo

 ZZS->(DBSetOrder(4))
 If Empty(cAnoMes)
     U_ITMsg("Ano / Mês não Preenchido, Favor Prenche-lo Antes de Prosseguir","Atenção",,1)
     _lRet	:= .F.
 ElseIf AOMS063B()
     U_ITMsg("Nâo Há Produtos, Favor Preencher ou Importar Algum Produtos Antes de Prosseguir","Atenção",,1)
     _lRet	:= .F.
 ElseIf Empty(cCoord)
     U_ITMsg("Coord/Vend não Preenchido, Favor Prenche-lo Antes de Prosseguir","Atenção",,1)
     _lRet	:= .F.
 Else
     If SA3->(MSSeek(FWxfilial("SA3")+cCoord))
        If SA3->A3_MSBLQL == '1'
           U_ITMsg("Coord/Vend Bloqueado.","Atenção",,1)
        EndIf
     Else
         U_ITMsg("Coord/Vend não encontrado.","Atenção",,1)
     EndIf
 EndIf

 If _lInclui .And. ZZS->(MSSeek(FWxfilial("ZZS")+AllTrim(cAnoMes)+AllTrim(cCoord)))
     U_ITMsg("Tabela Já Cadastrada, Favor alterar o Coordenador ou o Ano / Mês, para dar continuidade","Atenção",,1)
     _lRet	:= .F.
 ElseIf AllTrim(cAnoMes) < SubStr(DToS(dDataBase),1,6)
     U_ITMsg("Ano / Mes Menor que o Ano / Mês Atual","Atenção",,1)
     _lRet	:= .F.
 EndIf

 aCols   := ASort(aCols,,,{|x, y| x[1] < y[1]})//REORDENA A TABELA
 _cErro  := ""

 For X:= 1 To Len(aCols)
    _cErro:=""
    If !Atail(aCols[X])
        If (X+1) <= Len(aCols)
            If!Atail(aCols[X+1])
                If aCols [X,nPosProd] == aCols [X+1,nPosProd]
                    If X < Len(aCols)
                        lRt := .T.
                        _cErro += "[Produto: " + AllTrim(aCols[x,nPosProd])+ " duplicado] "
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf
    cbloq:= Posicione("SB1",1,FWxfilial("SB1")+aCols[x,nPosProd],"B1_MSBLQL")
    If cbloq == '1'
       _cErro += "[Produto: " + AllTrim(aCols[x,nPosProd]) +" Bloqueado] "
    EndIf
    If Empty(aCols[x,nPosVal])
       _cErro += "[Produto: " + AllTrim(aCols[x,nPosProd]) + " com valor zerado] "
    EndIf
    If aCols[X,nPos2Qtd] <= 0 .Or. aCols[X,nPosQtd] <= 0  .Or. aCols[X,nPos3Qtd] < 0
       _cErro += "[Produto: " + AllTrim(aCols[x,nPosProd]) + " com Quantidade(s) invalida(s).]"
    EndIf
    If !Empty(_cErro)
        _cErro:="Linha " + StrZero(X,6) + " com erro(s): "+ _cErro
        AAdd(_aErros,{.F.,_cErro})
    EndIf
 Next X

 If Len(_aErros) > 0
     U_ITListBox("Quantidade de erros: "+AllTrim(Str(Len(_aErros))),{"","Erros"},_aErros,,4)
     _lRet	:= .F.
 EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS063V
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Funcao de validadação e gatilhos ZZS_QTD / ZZS_QTD2UM / ZZS_QTD3UM
Parametros--------: _cCampo: origem da chamada
Retorno-----------: _xRet: Retorno de acorodo com a chamada
===============================================================================================================================
*/
User Function AOMS063V(_cCampo As Char) As Logical

 Local _xRet  := 0 As Numeric
 Local _nPos  := 0 As Numeric
 Local C      := 0 As Numeric
 Local _nPerc := 0 As Numeric
 Local _dData As Date
 Local xObj   As Object

 If _cCampo == "%" //U_AOMS063V("%")

    _xRet := .T.
    N:=oMsMGet:oBrowse:nAt
    C:=oMsMGet:oBrowse:nColPos//Posicao do Campo %
    aCols:=oMsMGet:aCols
    _dData:=aCols[N,C-1]
    _nPerc:=&(ReadVar())//aCols[N,C]
    If Empty(_dData) .Or. LEFT(DToC(_dData),5) = "29/02"//ANOS BISEXTOS
       aCols[N,C]  :=0
       &(ReadVar()):=0
    Else
       Return NaoVazio(_nPerc) .And. Positivo(_nPerc)
    EndIf
    oMsMGet:aCols:=aCols
    oMsMGet:oBrowse:Refresh()

 ElseIf _cCampo == 'CCOORD'
    _xRet := .T.
    cNmCoor:= Posicione("SA3",1,FWxfilial("SA3")+cCoord,"A3_NOME")
    cTipoor:= SA3->A3_I_TIPV//V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR;N=GERENCIA NACIONAL
    If cTipoor == "V"
        cTipoor := "Vendedor"
    ElseIf cTipoor == "C"
        cTipoor := "Coordenador"
    ElseIf cTipoor == "G"
        cTipoor := "Gerente"
    ElseIf cTipoor == "S"
        cTipoor := "Supervisor"
    ElseIf cTipoor == "N"
        cTipoor := "Gerencia Nacional"
    Else
        cTipoor := "Tipo de Vendedor não encontrado"
    EndIf
    If Len(aCols) > 0 .And. Len(aCols[1]) > 0 .And. aCols[1][1] == 'ZZS_COD'
        _xRet := .F.
    EndIf

 ElseIf _cCampo == "ZZS_QTD"//Contra dominio ZZS_QTD2UM

    xObj          := CallMod2Obj()
    N             := xObj:oBrowse:nat
    _nPos         := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'} )
    M->ZZS_COD    := aCols[N,_nPos]
    _xRet         := U_ITConv(M->ZZS_COD,M->ZZS_QTD   ,1,2)//Retona no ZZS_QTD2UM
    M->ZZS_QTD3UM := U_ITConv(M->ZZS_COD,M->ZZS_QTD   ,1,3)//Retona no ZZS_QTD3UM
    _nPos         := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'} )
    aCols[N,_nPos]:= M->ZZS_QTD3UM

 ElseIf _cCampo == "ZZS_QTD2UM"//Contra dominio ZZS_QTD

    xObj          := CallMod2Obj()
    N             := xObj:oBrowse:nat
    _nPos         := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'} )
    M->ZZS_COD    := aCols[N,_nPos]
    _xRet         := U_ITConv(M->ZZS_COD,M->ZZS_QTD2UM,2,1)//Retona no ZZS_QTD
    M->ZZS_QTD3UM := U_ITConv(M->ZZS_COD,M->ZZS_QTD2UM,2,3)//Retona no ZZS_QTD3UM
    _nPos         := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'} )
    aCols[N,_nPos]:= M->ZZS_QTD3UM

 ElseIf _cCampo == "ZZS_QTD3UM"//Contra dominio ZZS_QTD

    xObj             := CallMod2Obj()
    N                := xObj:oBrowse:nat
    _nPos            := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_3UM'} )
    M->ZZS_3UM       := aCols[N,_nPos]
    If Empty(M->ZZS_3UM)
       //M->ZZS_QTD3UM := 0//Editado
       _nPos         := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'} )
       aCols[N,_nPos]:= 0
       _nPos         := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD'} )
       _xRet         := aCols[N,_nPos]//Retona no ZZS_QTD o conteudo dele mesmo
    Else
       _nPos         := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'} )
       M->ZZS_COD    := aCols[N,_nPos]
       _xRet         := U_ITConv(M->ZZS_COD,M->ZZS_QTD3UM,3,1)//Retona no ZZS_QTD
       M->ZZS_QTD2UM := U_ITConv(M->ZZS_COD,M->ZZS_QTD3UM,3,2)//Retona no ZZS_QTD2UM
       _nPos         := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD2UM'} )
       aCols[N,_nPos]:= M->ZZS_QTD2UM
    EndIf

 EndIf

Return _xRet

/*
===============================================================================================================================
Programa----------: AOMS063D
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Botão Imp. Produtos - Importação de Produtos para Inclusão
Parametros--------: cAnoMes,cCoord,nRet
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS063D(cAnoMes As Char,cCoord As Char,nRet As Numeric)
 Local oDlgAno  As Object
 Local nGet1:=0 As Numeric
 Local nPorc:=0 As Numeric

 ZZS->(DBSetOrder(4))

 If Empty(cCoord)

     U_ITMsg("Coord/Vend não Preenchido, Favor Prenche-lo Antes de Prosseguir","Atenção",,1)

 ElseIf ZZS->(MSSeek(FWxfilial("ZZS")+AllTrim(cAnoMes)+AllTrim(cCoord)))

     U_ITMsg("Tabela Já Cadastrada, Favor alterar o Coordenador ou o Ano / Mês, para dar continuidade","Atenção",,1)

 ElseIf Empty(cAnoMes)

     U_ITMsg("Ano / Mês não Preenchido, Favor Prenche-lo Antes de Prosseguir","Atenção",,1)

 ElseIf AllTrim(cAnoMes) < SubStr(DToS(dDataBase),1,6)

     U_ITMsg("Ano / Mes Menor Que o Ano / Mês Atual","Atenção",,1)

 Else

     DEFINE MSDIALOG oDlgAno FROM 0,0 TO 150,200 PIXEL TITLE 'Digite a Porcentagem'

     @10,05 Say "Digite a Porcentagem para o Calculo:" Size 91,08 COLOR CLR_BLACK PIXEL OF oDlgAno
     @30,10 MSGet nGet1 Picture "@E 999,999.99" Size 60,10 Pixel Of oDlgAno

     @50,15 Button "Ok" Size 20,10 PIXEL OF oDlgAno action (oDlgAno:end())

     ACTIVATE MSDIALOG oDlgAno CENTERED

     nPorc:= nGet1/100

     FWMsgRun( ,{|oProc| U_AOMS063W(nPorc,oProc) }, 'Aguarde!' , 'Carregando os dados...'  )

 EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS063Y ()
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Visualizar Cadastro de Previsão de Vendas
Parametros--------: oProc As Object
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063Y(oProc As Object)

 Local cTitulo    := "Visualização de Metas de Vendas" As Char
 Local _nCont     := 0 As Numeric
 Local aYesFields := {} As Array
 Local aCGD       := {} As Array
 Local ACORDW     := {} As Array

 Private  nOpcx:= 2 As Numeric // Opção de Modelo da GetDados

 If(Empty(TMP->ANOMES))

    U_ITMsg("Não Há Tabela A ser Visualizada","Atenção",,1)

 Else

    nUsado:=0
    aHeader:={}
    aCols:={}

    //Carrega aheader
    aYesFields := {"ZZS_COD","ZZS_DESCR","ZZS_DESCD","ZZS_QTD","ZZS_UM","ZZS_QTD2UM","ZZS_2UM","ZZS_QTD3UM","ZZS_3UM","ZZS_VALOR"}
    FillGetDados(2,"ZZS",1,,,,, aYesFields ,,,, .T. ,,,,,, )

    //Limpa dois ultimos campos do aheader
    asize(aheader,Len(aheader)-2)

    cAnoMes  := Space(06)
    cCoord	 := Space(06)
    cNmCoor	 := Space(60)


    aC:={}
    // aC[n,1] = Nome da Variavel Ex.:"cCliente"
    // aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
    // aC[n,3] = Titulo do Campo
    // aC[n,4] = Picture
    // aC[n,5] = Validacao
    // aC[n,6] = F3
    // aC[n,7] = Se campo e' editavel .T. se nao .F.

    cAnoMes       := TMP->ANOMES
    cCoord	      := TMP->COORD
    cNmCoor		  := AllTrim(TMP->NMCOORD)
    cTipoor		  := Posicione("SA3",1,FWxfilial("SA3")+TMP->COORD,"A3_I_TIPV")//V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR;N=GERENCIA NACIONAL
    If cTipoor == "V"
        cTipoor := "Vendedor"
    ElseIf cTipoor == "C"
        cTipoor := "Coordenador"
    ElseIf cTipoor == "G"
        cTipoor := "Gerente"
    ElseIf cTipoor == "S"
        cTipoor := "Supervisor"
    ElseIf cTipoor == "N"
        cTipoor := "Gerencia Nacional"
    Else
        cTipoor := "Tipo de Vendedor não encontrado"
    EndIf

    //"Visualização de Metas de Vendas"
    AAdd(aC,{"cAnoMes",{15,003}," Ano-Mes ","@R 9999-99",,,.F.})
    AAdd(aC,{"cCoord" ,{15,080}," Codigo " ,"@!","U_AOMS063V('CCOORD') .And. (ExistCPO('SA3'))","SA3",.F.})
    AAdd(aC,{"cNmCoor",{15,155}," Nome "   ,"@!",,,.F.})
    AAdd(aC,{"cTipoor",{30,003}," Tipo "   ,"@!",,,.F.})
    //================================================================
    // Array com descricao dos campos do Rodape do Modelo 2
    //================================================================

    aR:={}
    // aR[n,1] = Nome da Variavel Ex.:"cCliente"
    // aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
    // aR[n,3] = Titulo do Campo
    // aR[n,4] = Picture
    // aR[n,5] = Validacao
    // aR[n,6] = F3
    // aR[n,7] = Se campo e' editavel .T. se nao .F.

    aCols:= {}
    _nCont:=0
    //------------MONTA OS ITENS COM OS DADOS-----------------------//
    ZZS->(DBSetOrder(7))//ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD+ZZS_DATA
    ZZS->(MSSeek(FWxfilial("ZZS")+cAnoMes+cCoord))
    While ZZS->(!Eof()).AND. cAnoMes == ZZS->ZZS_ANOMES .And. cCoord == ZZS->ZZS_COOR
       If !Empty(ZZS->ZZS_DATA)
          ZZS->(DBSkip())
          Loop
       EndIf
       _nCont++
       oProc:cCaption := ( "V-Lendo Metas: " + StrZero(_nCont,5))
       ProcessMessages()
       AAdd(aCols,{ZZS->ZZS_COD,ZZS->ZZS_DESCR,ZZS->ZZS_DESCD,ZZS->ZZS_QTD,ZZS->ZZS_UM,ZZS->ZZS_QTD2UM,;
                   ZZS->ZZS_2UM,ZZS->ZZS_QTD3UM,ZZS->ZZS_3UM,ZZS->ZZS_VALOR,.F.})//Novos
       ZZS->(DBSkip())
    EndDo

    //================================================================
    // Array com coordenadas da GetDados no modelo2
    //================================================================
    aButtons := {}
    AAdd(aButtons,{"",{|| AOMS063X(.T.) },"xGerar XML"  ,"Gerar XML"  })
    AAdd(aButtons,{"",{|| AOMS063X(.F.) },"xGerar Excel","Gerar Excel"})

    _bProdDia:={|| FWMsgRun( ,{|oProc| AOMS063Ger("LISTA_META_POR_DIA",cAnoMes,cCoord) }, 'V-Aguarde!' , 'V-Lendo As datas/metas do Produto...'  )  }
    AAdd(aButtons,{"",_bProdDia,"x% por Produto/Dia","% por Produto/Dia"})

    aCGD:={60,06,26,74}
    ACORDW  := {ASIZE[7],0,ASIZE[6],ASIZE[5]}

    // Chamada da Modelo2
    //    cTitulo [ aC ] [ aR ] [ aGd ] [ nOp ] [ cLinhaOk ] [ cTudoOk ]aGetsD [ bF4 ] [ cIniCpos ] [ nMax ] [ aCordW ] [ lDelGetD ] [ lMaximazed ] [ aButtons ]
    Modelo2(cTitulo,aC	,  aR	, aCGD	,nOpcx	,  ".T."	,  ".T."   ,	  ,		  ,			   ,  9999	,  ACORDW   ,  .F.       ,    .T.  		, aButtons)

 EndIf

Return


/*
===============================================================================================================================
Programa----------: AOMS063C
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Copia Cadastro de Previsão de Vendas - CHAMADO 3008
Parametros--------: oProc - Objeto do processo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063C(oProc As Object)

 Local cTitulo  := "Copia de Metas de Vendas" As Char
 Local aCGD     := {}  As Array
 Local ACORDW   := {}  As Array
 Local _l       := 00  As Numeric
 Local _nCont   := 00  As Numeric
 Local lRetMod2 := .F. As Logical  // Retorno da função Modelo2 - .T. Confirmou / .F. Cancelou
 Local cLinhaOk := ""  As Char
 Local cTudoOk  := ""  As Char
 Private nOpcx  := 03  As Numeric // Opção de Modelo da GetDados

 If(Empty(TMP->ANOMES))

     U_ITMsg("Não Há Tabela a ser Copiada","Atenção",,1)

 Else

     nUsado:=0
     aHeader:={}
     aCols:={}

     //Carrega aheader
     aYesFields := {"ZZS_COD","ZZS_DESCR","ZZS_DESCD","ZZS_QTD","ZZS_UM","ZZS_QTD2UM","ZZS_2UM","ZZS_QTD3UM","ZZS_3UM","ZZS_VALOR"}
     FillGetDados(2,"ZZS",1,,,,, aYesFields ,,,, .T. ,,,,,, )

     //Limpa dois ultimos campos do aheader
     asize(aheader,Len(aheader)-2)


     cAnoMes:= TMP->ANOMES
     cCoord := TMP->COORD
     cNmCoor:= TMP->NMCOORD
     cTipoor:= Posicione("SA3",1,FWxfilial("SA3")+TMP->COORD,"A3_I_TIPV")//V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR;N=GERENCIA NACIONAL
     If cTipoor == "V"
         cTipoor:= "Vendedor"
     ElseIf cTipoor == "C"
         cTipoor:= "Coordenador"
     ElseIf cTipoor == "G"
         cTipoor:= "Gerente"
     ElseIf cTipoor == "S"
         cTipoor:= "Supervisor"
     ElseIf cTipoor == "N"
         cTipoor:= "Gerencia Nacional"
     Else
         cTipoor:= "Tipo de Vendedor não encontrado"
     EndIf

     aC:={}
     // aC[n,1] = Nome da Variavel Ex.:"cCliente"
     // aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
     // aC[n,3] = Titulo do Campo
     // aC[n,4] = Picture
     // aC[n,5] = Validacao
     // aC[n,6] = F3
     // aC[n,7] = Se campo e' editavel .T. se nao .F.

     //"COPIA DE METAS DE VENDAS"
     AAdd(aC,{"cAnoMes",{15,003}," Ano-Mes ","@R 9999-99",,,.T.})
     AAdd(aC,{"cCoord" ,{15,080}," Codigo " ,"@!","U_AOMS063V('CCOORD') .And. (ExistCPO('SA3'))","SA3",.T.})
     AAdd(aC,{"cNmCoor",{15,155}," Nome "   ,"@!",,,.F.})
     AAdd(aC,{"cTipoor",{30,003}," Tipo "   ,"@!",,,.F.})

     //================================================================
     // Array com descricao dos campos do Rodape do Modelo 2
     //================================================================

     aR:={}
     // aR[n,1] = Nome da Variavel Ex.:"cCliente"
     // aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
     // aR[n,3] = Titulo do Campo
     // aR[n,4] = Picture
     // aR[n,5] = Validacao
     // aR[n,6] = F3
     // aR[n,7] = Se campo e' editavel .T. se nao .F.

     aCols:= {}

     //------------MONTA OS ITENS COM OS DADOS-----------------------//
     _nCont:=0
     ZZS->(DBSetOrder(7))//ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD+ZZS_DATA
     ZZS->(MSSeek(FWxfilial("ZZS")+cAnoMes+cCoord))
     While ZZS->(!Eof()).AND. cAnoMes == ZZS->ZZS_ANOMES .And. cCoord == ZZS->ZZS_COOR
        If !Empty(ZZS->ZZS_DATA)
           ZZS->(DBSkip())
           Loop
        EndIf
        _nCont++
        oProc:cCaption := ( "C-Lendo Metas: " + StrZero(_nCont,5))
        ProcessMessages()
        AAdd(aCols,{ZZS->ZZS_COD,ZZS->ZZS_DESCR,ZZS->ZZS_DESCD,ZZS->ZZS_QTD,ZZS->ZZS_UM,ZZS->ZZS_QTD2UM,;
                    ZZS->ZZS_2UM,ZZS->ZZS_QTD3UM,ZZS->ZZS_3UM,ZZS->ZZS_VALOR,.F.})//Novos
        ZZS->(DBSkip())
     EndDo

     // Array com coordenadas da GetDados no modelo2
     aCGD:={60,06,26,74}
     ACORDW  := {ASIZE[7],0,ASIZE[6],ASIZE[5]}

     cLinhaOk:="U_AOMS063O()"
     cTudoOk :="U_AOMS063Z(.T.)"//"COPIA DE METAS DE VENDAS"

     aButtons:={}
     _bProdDia:={|| FWMsgRun( ,{|oProc| AOMS063Ger("LISTA_META_POR_DIA",cAnoMes,cCoord) }, 'C-Aguarde!' , 'C-Lendo As datas/metas do Produto...'  )  }
     AAdd(aButtons,{"",_bProdDia,"x% por Produto/Dia","% por Produto/Dia"})

     // Chamada da Modelo2
     // lRetMod2 = .T. se confirmou
     // lRetMod2 = .F. se cancelou
     //              cTitulo [ aC ] [ aR ] [ aGd ] [ nOp ] [ cLinhaOk ] [ cTudoOk ]aGetsD [ bF4 ] [ cIniCpos ] [ nMax ] [ aCordW ] [ lDelGetD ] [ lMaximazed ] [ aButtons ]
     lRetMod2:=Modelo2(cTitulo,aC  ,  aR  , aCGD  ,nOpcx  ,  cLinhaOk  ,  cTudoOk ,      ,       ,            ,  9999  ,  ACORDW  ,            ,    .T.       ,  aButtons)

     cChama := "NÃO RECARREGAR" //Se Cancelou

     If lRetMod2 // Gravacao. . .
         lGravouDados:=.T.

         nPosProd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'   } )
         nPosDesc := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCR' } )
         nPosDesD := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCD' } )
         nPosUM	  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_UM'    } )
         nPosQtd  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD'   } )
         nPos2UM  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_2UM'   } )
         nPos2Qtd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD2UM'} )
         nPos3UM  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_3UM'   } )//Novo
         nPos3Qtd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'} )//Novo
         nPosVal  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_VALOR' } )//Novo

         _cReg:=AllTrim(Str(Len(aCols)))
         _nCont:=0

         For _l := 1 To Len(aCols)

             _nCont++
             oProc:cCaption := ( "Copiando Metas: " + StrZero(_nCont,5) + " de " + _cReg)
             ProcessMessages()

             If !aCols[_l,Len(aHeader)+1]

                 ZZS->(RecLock("ZZS",.T.))//INCLUSAO2
                 ZZS->ZZS_FILIAL	:= FWxfilial("ZZS")
                 ZZS->ZZS_COD	:= aCols[_l,nPosProd]
                 ZZS->ZZS_DESCR	:= aCols[_l,nPosDesc]
                 ZZS->ZZS_DESCD	:= aCols[_l,nPosDesD]
                 ZZS->ZZS_UM		:= aCols[_l,nPosUM]
                 ZZS->ZZS_QTD   	:= aCols[_l,nPosQtd]
                 ZZS->ZZS_2UM	:= aCols[_l,nPos2UM]
                 ZZS->ZZS_QTD2UM	:= aCols[_l,nPos2Qtd]
                 ZZS->ZZS_3UM    := aCols[_l,nPos3UM ]//Novo
                 ZZS->ZZS_QTD3UM := aCols[_l,nPos3Qtd]//Novo
                 ZZS->ZZS_VALOR  := aCols[_l,nPosVal ]//Novo
                 ZZS->ZZS_TIPOV  := Posicione("SA3",1,FWxfilial("SA3")+cCoord,"A3_I_TIPV")//Novo
                 ZZS->ZZS_COOR	:= cCoord
                 ZZS->ZZS_NMCOOR	:= cNmCoor
                 ZZS->ZZS_ANOMES	:= cAnoMes
                 ZZS->(MSUnLock())//SEM DATA

                 ZGW->(RecLock("ZGW",.T.))//INCLUSAO2
                 ZGW->ZGW_FILIAL	:= FWxfilial("ZGW")
                 ZGW->ZGW_COD	:= aCols[_l,nPosProd]
                 ZGW->ZGW_DESCR	:= aCols[_l,nPosDesc]
                 ZGW->ZGW_DESCD	:= aCols[_l,nPosDesD]
                 ZGW->ZGW_UM		:= aCols[_l,nPosUM]
                 ZGW->ZGW_QTD   	:= aCols[_l,nPosQtd]
                 ZGW->ZGW_2UM	:= aCols[_l,nPos2UM]
                 ZGW->ZGW_QTD2UM	:= aCols[_l,nPos2Qtd]
                 ZGW->ZGW_3UM	:= ZZS->ZZS_3UM   //Novo
                 ZGW->ZGW_QTD3UM	:= ZZS->ZZS_QTD3UM//Novo
                 ZGW->ZGW_VALOR  := ZZS->ZZS_VALOR //Novo
                 ZGW->ZGW_TIPOV  := ZZS->ZZS_TIPOV //Novo
                 ZGW->ZGW_DATAM  := ZZS->ZZS_DATA  //Novo
                 ZGW->ZGW_COOR	:= cCoord
                 ZGW->ZGW_NMCOOR	:= cNmCoor
                 ZGW->ZGW_ANOMES	:= cAnoMes
                 ZGW->ZGW_OPER   := "INCLUSAO2"
                 ZGW->ZGW_USER   := _cUserName
                 ZGW->ZGW_DATA   := Date()
                 ZGW->ZGW_HORA   := Time()
                 ZGW->(MSUnLock())

                 AOMS063Ger("GERAR_VALORES_POR_DATA",ZZS->ZZS_ANOMES)//COM DATA

             EndIf
         Next _l

         cChama = "RECARREGA"
         oDlgLIb:End()

     EndIf
 EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS063Z
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Replicar Cadastro de Previsão de Vendas - CHAMADO 3008
Parametros--------: oProc
Retorno-----------: .T. - Se Cancelar / .F. Se Recarregar
===============================================================================================================================
*/
Static Function AOMS063Z(oProc As Object)

 Local cAnoMes := TMP->ANOMES As Char
 Local cCoord  := TMP->COORD As Char
 Local cNmCoord:= TMP->NMCOORD As Char
 Local _aParAux:= {} As Array
 Local _aParRet:= {} As Array
 Local  I := 0 As Numeric

 cChama := "NÃO RECARREGAR" //Se Cancelar

 If(Empty(TMP->ANOMES))
     U_ITMsg("Não Há Tabela a ser Replicada","Atenção","Posicione em Ano / mes Preenchido.",1)
     Return .F.
 EndIf

 MV_PAR01 := 0

 AAdd( _aParAux ,{ 1 ,"Qtde (Em Meses) a ser replicado" ,MV_PAR01,"@E 99","",""   ,"" ,020 ,.T. } )

 For I := 1 To Len( _aParAux )
     AAdd( _aParRet ,_aParAux[I][03] )
 Next I

 //          aParametros,cTitle                            ,@aRet    ,[bOk]  ,[ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ]
 If !ParamBox( _aParAux ,"Qtde (Em Meses) a ser replicado" ,@_aParRet,       ,/*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
     Return .T.
 EndIf

 FWMsgRun( ,{|oProc| AOMS063Q(MV_PAR01,cAnoMes,cCoord,cNmCoord,oProc) } , "Processando..." , "Iniciando o processamento..." )

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS063Q
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Processa Replicacao Cadastro de Previsão de Vendas
Parametros--------: nPeriod - Quantidade de periodos a replicar
                    cAnoMes - Data do movimento a replicar
                    cCoord  - Coordenador a replicar
                    cNmCoor - numero do coordenador
                    oProc   - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063Q(nPeriod As Numeric,cAnoMes As Char,cCoord As Char,cNmCoor As Char,oProc As Object)
 Local x As Numeric
 Local _nCont:=0 As Numeric
 Local _cAlias:= GetNextAlias() As Char
 Local _nTotal:= 0 As Numeric
 Local cAMes:= cAnoMes As Char
 Local cRep := "" As Char
 Local cGravados:="" As Char
 Local cJaGravados:="" As Char

 lGravouDados:=.F.
 ZZS->(DBSetOrder(4))
 For x:=1 To nPeriod

     ZZS->(MSSeek(FWxfilial("ZZS")+cAnoMes+cCoord))

     If StrZero((Val(SubStr(cAMes,5,2)) + 1 ),2) > "12"
         cAMes:=StrZero((Val(SubStr(cAMes,1,4)) + 1 ),4)+"01"
     Else
         cAMes:=StrZero( Val(SubStr(cAMes,1,4))      ,4)+StrZero((Val(SubStr(cAMes,5,2)) + 1 ),2)
     EndIf

     If !ZZS->(MSSeek(FWxfilial("ZZS")+cAMes+cCoord))

         cRep:= " SELECT ZZS_COD COD, ZZS_DESCR DESCR, ZZS_DESCD DESCD, ZZS_QTD QTD1UM, ZZS_UM UM1, ZZS_QTD2UM QTD2UM, "
         cRep+= " ZZS_VALOR,ZZS_TIPOV,ZZS_QTD3UM,ZZS_3UM , "//Novos
         cRep+= " ZZS_2UM UM2
         cRep+= " FROM ZZS010
         cRep+= " WHERE ZZS_ANOMES = '"+cAnoMes+"'
         cRep+= " AND ZZS_COOR = '"+cCoord+"'
         cRep+= " AND D_E_L_E_T_ = ' ' "
         cRep+= " AND ZZS_DATA = ' ' "
         cRep+= " AND ZZS_FILIAL = '"+FWxfilial("ZZS")+"'
         cRep+= " ORDER BY ZZS_COD "

         oProc:cCaption := ( "Criando Ano / Mes / Codigo: "+ cAMes+" / "+cCoord )
         ProcessMessages()

         //==============================================
         // Monta Area de Trabalho executando a Query
         //==============================================
         MPSysOpenQuery( cRep , _cAlias)

         _nCont:=0
         _nTotal:=0
         DBSelectArea(_cAlias)
         COUNT TO _nTotal
         _nTotal:=AllTrim(Str(_nTotal))
         (_cAlias)->(DBGoTop())

         While (_cAlias)->(!Eof())

             _nCont++
             oProc:cCaption := ( StrZero(X,2)+" Copia: " + StrZero(_nCont,4) + " de " + _nTotal+" "+cGravados)
             ProcessMessages()

             ZZS->(RecLock("ZZS",.T.))//INCLUSAO3
             ZZS->ZZS_FILIAL	:= FWxfilial("ZZS")
             ZZS->ZZS_COD	:= (_cAlias)->COD
             ZZS->ZZS_DESCR	:= (_cAlias)->DESCR
             ZZS->ZZS_DESCD	:= (_cAlias)->DESCD
             ZZS->ZZS_UM		:= (_cAlias)->UM1
             ZZS->ZZS_QTD   	:= (_cAlias)->QTD1UM
             ZZS->ZZS_2UM	:= (_cAlias)->UM2
             ZZS->ZZS_QTD2UM	:= (_cAlias)->QTD2UM
             ZZS->ZZS_3UM    := (_cAlias)->ZZS_3UM   //Novo
             ZZS->ZZS_QTD3UM := (_cAlias)->ZZS_QTD3UM//Novo
             ZZS->ZZS_VALOR  := (_cAlias)->ZZS_VALOR //Novo
             ZZS->ZZS_TIPOV  := (_cAlias)->ZZS_TIPOV //Novo
             ZZS->ZZS_COOR	:= cCoord
             ZZS->ZZS_NMCOOR	:= cNmCoor
             ZZS->ZZS_ANOMES	:= cAMes
             ZZS->(MSUnLock())

             ZGW->(RecLock("ZGW",.T.))//INCLUSAO3
             ZGW->ZGW_FILIAL	:= FWxfilial("ZGW")
             ZGW->ZGW_COD	:= (_cAlias)->COD
             ZGW->ZGW_DESCR	:= (_cAlias)->DESCR
             ZGW->ZGW_DESCD	:= (_cAlias)->DESCD
             ZGW->ZGW_UM		:= (_cAlias)->UM1
             ZGW->ZGW_QTD   	:= (_cAlias)->QTD1UM
             ZGW->ZGW_2UM	:= (_cAlias)->UM2
             ZGW->ZGW_QTD2UM	:= (_cAlias)->QTD2UM
             ZGW->ZGW_3UM    := ZZS->ZZS_3UM   //Novo
             ZGW->ZGW_QTD3UM := ZZS->ZZS_QTD3UM//Novo
             ZGW->ZGW_VALOR	:= ZZS->ZZS_VALOR //Novo
             ZGW->ZGW_TIPOV	:= ZZS->ZZS_TIPOV //Novo
             ZGW->ZGW_DATAM  := ZZS->ZZS_DATA  //Novo
             ZGW->ZGW_COOR	:= cCoord
             ZGW->ZGW_NMCOOR	:= cNmCoor
             ZGW->ZGW_ANOMES	:= cAMes
             ZGW->ZGW_OPER   := "INCLUSAO3"
             ZGW->ZGW_USER   := _cUserName
             ZGW->ZGW_DATA   := Date()
             ZGW->ZGW_HORA   := Time()
             ZGW->(MSUnLock())

             AOMS063Ger("GERAR_VALORES_POR_DATA",ZZS->ZZS_ANOMES)

             (_cAlias)->(DBSkip())
             lGravouDados:=.T.
             If !"["+cAMes+"] " $ cGravados
                 cGravados+="["+cAMes+"] "
             EndIf
         EndDo
        (_cAlias)->(DBCloseArea())
     Else
        cJaGravados+="["+cAMes+"] "
     EndIf
 Next x

 If lGravouDados
    U_ITMsg("Replicação Concluida Com Sucesso","Atenção","Mes(es) gravado(s): "+cGravados,2)
    cChama = "RECARREGA"
    oDlgLIb:End()
 Else
    U_ITMsg("Nenhum registro replicado. Esse(s) mes(es) já estão gravado(s): "+cJaGravados,"Atenção","Selecione um mes que não tenha metas no mes seguinte em diante.",2)
 EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS063G
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: ALTERAR CADASTRO DE PREVISÃO DE VENDAS
Parametros--------: oProc - Objeto do processo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063G(oProc As Object)

 Local cTitulo	:= "Alteração de Metas de Vendas" As Char
 Local lRetMod2 := .F. As Logical // Retorno da função Modelo2 - .T. Confirmou / .F. Cancelou
 Local _l := 0 As Numeric
 Local cLinhaOk := "" As Char
 Local cTudoOk  := "" As Char
 Local aCGD     := {} As Array
 Local ACORDW   := {} As Array
 Local aButtons := {} As Array
 Private nOpcx  := 4 As Numeric

 If(Empty(TMP->ANOMES))
   U_ITMsg("Não Há Tabela a ser alterada","Atenção",,1)
   Return
 ElseIf TMP->ANOMES < LEFT(DToS(Date()),6)
   U_ITMsg("Metas com data menor que "+LEFT(DToS(Date()),4)+"-"+SubStr(DToS(Date()),5,2)+" não podem serem alteradas.","Atenção",,1)
   Return
 EndIf

 nUsado:=0
 aHeader:={}
 aCols:={}

 //Carrega aheader
 aYesFields := {"ZZS_COD","ZZS_DESCR","ZZS_DESCD","ZZS_QTD","ZZS_UM","ZZS_QTD2UM","ZZS_2UM","ZZS_QTD3UM","ZZS_3UM","ZZS_VALOR"}
 FillGetDados(2,"ZZS",1,,,,, aYesFields ,,,, .T. ,,,,,, )

 //Limpa dois ultimos campos do aheader
 asize(aheader,Len(aheader)-2)


 cAnoMes:= TMP->ANOMES
 cCoord := TMP->COORD
 cNmCoor:= TMP->NMCOORD
 cTipoor:= Posicione("SA3",1,FWxfilial("SA3")+TMP->COORD,"A3_I_TIPV")//V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR;N=GERENCIA NACIONAL
 If cTipoor == "V"
     cTipoor := "Vendedor"
 ElseIf cTipoor == "C"
     cTipoor := "Coordenador"
 ElseIf cTipoor == "G"
     cTipoor := "Gerente"
 ElseIf cTipoor == "S"
     cTipoor := "Supervisor"
 ElseIf cTipoor == "N"
     cTipoor := "Gerencia Nacional"
 Else
     cTipoor := "Tipo de Vendedor não encontrado"
 EndIf

 aC:={}
 // aC[n,1] = Nome da Variavel Ex.:"cCliente"
 // aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
 // aC[n,3] = Titulo do Campo
 // aC[n,4] = Picture
 // aC[n,5] = Validacao
 // aC[n,6] = F3
 // aC[n,7] = Se campo e' editavel .T. se nao .F.
 //"ALTERAÇÃO DE METAS DE VENDAS"
 AAdd(aC,{"cAnoMes",{15,003}," Ano-Mes ","@R 9999-99",,,.F.})
 AAdd(aC,{"cCoord" ,{15,080}," Codigo " ,"@!","U_AOMS063V('CCOORD') .And. (ExistCPO('SA3'))","SA3",.F.})
 AAdd(aC,{"cNmCoor",{15,155}," Nome "   ,"@!",,,.F.})
 AAdd(aC,{"cTipoor",{30,003}," Tipo "   ,"@!",,,.F.})

 // Array com descricao dos campos do Rodape do Modelo 2

 aR:={}
 // aR[n,1] = Nome da Variavel Ex.:"cCliente"
 // aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
 // aR[n,3] = Titulo do Campo
 // aR[n,4] = Picture
 // aR[n,5] = Validacao
 // aR[n,6] = F3
 // aR[n,7] = Se campo e' editavel .T. se nao .F.
 aCols:= {}
 //------------MONTA OS ITENS COM OS DADOS-----------------------//
 _nCont:=0
 ZZS->(DBSetOrder(7))//ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD+ZZS_DATA
 ZZS->(MSSeek(FWxfilial("ZZS")+cAnoMes+cCoord))
 While ZZS->(!Eof()).AND. cAnoMes == ZZS->ZZS_ANOMES .And. cCoord == ZZS->ZZS_COOR
    If !Empty(ZZS->ZZS_DATA)
       ZZS->(DBSkip())
       Loop
    EndIf
    _nCont++
    oProc:cCaption := ( "V-Lendo Metas: " + StrZero(_nCont,5))
    ProcessMessages()
    AAdd(aCols,{ZZS->ZZS_COD,ZZS->ZZS_DESCR,ZZS->ZZS_DESCD,ZZS->ZZS_QTD,ZZS->ZZS_UM,ZZS->ZZS_QTD2UM,;
                ZZS->ZZS_2UM,ZZS->ZZS_QTD3UM,ZZS->ZZS_3UM,ZZS->ZZS_VALOR,.F.})//Novos
    ZZS->(DBSkip())
 EndDo

 // Array com coordenadas da GetDados no modelo2
 aCGD:={60,06,26,74}
 ACORDW  := {ASIZE[7],0,ASIZE[6],ASIZE[5]}
 aButtons:={}
 _bProdDia:={|| FWMsgRun( ,{|oProc| AOMS063Ger("LISTA_META_POR_DIA",cAnoMes,cCoord) }, 'A-Aguarde!' , 'A-Lendo As datas/metas do Produto...'  )  }
 AAdd(aButtons,{"",_bProdDia,"x% por Produto/Dia","% por Produto/Dia"})
 cLinhaOk:="U_AOMS063O()"
 cTudoOk :="U_AOMS063Z(.F.)"//"ALTERAÇÃO DE METAS DE VENDAS"
 // Chamada da Modelo2
 // lRetMod2 = .T. se confirmou
 // lRetMod2 = .F. se cancelou
 //		          cTitulo [ aC ] [ aR ] [ aGd ] [ nOp ] [ cLinhaOk ] [ cTudoOk ] aGetsD [ bF4 ] [ cIniCpos ] [ nMax ] [ aCordW ] [ lDelGetD ] [ lMaximazed ] [ aButtons ]
 lRetMod2:=Modelo2(cTitulo,aC    ,  aR  , aCGD  ,nOpcx  ,  cLinhaOk  ,  cTudoOk  ,      ,       ,            ,  9999  ,  ACORDW  ,    .T.     ,    .T.       ,aButtons)

 cChama := "NÃO RECARREGAR" //Se Cancelou
 lGravouDados:=.F.//Se Cancelou

 If lRetMod2 // Gravacao. . .

    nPosProd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'   } )
    nPosDesc := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCR' } )
    nPosDesD := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCD' } )
    nPosUM	 := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_UM'    } )
    nPosQtd	 := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD'   } )
    nPos2UM	 := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_2UM'   } )
    nPos2Qtd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD2UM'} )
    nPos3UM  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_3UM'   } )//Novo
    nPos3Qtd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'} )//Novo
    nPosVal  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_VALOR' } )//Novo

    _cReg:=AllTrim(Str(Len(aCols)))
    _nCont:=0

    ZZS->(DBSetOrder(7))//ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD+ZZS_DATA
    For _l := 1 To Len(aCols)

        _nCont++
        oProc:cCaption := ( "Gravando Metas: " + StrZero(_nCont,5) + " de " + _cReg)
        ProcessMessages()

        If !Atail(aCols[_l])

            If !ZZS->(MSSeek(FWxfilial("ZZS")+cAnoMes+cCoord+aCols[_l,nPosProd]+"      "))//INCLUSAO
               ZZS->(RecLock("ZZS",.T.))//INCLUSAO4
               ZZS->ZZS_ANOMES	:= cAnoMes
               ZZS->ZZS_COOR 	:= cCoord
               ZZS->ZZS_NMCOOR	:= cNmCoor
               _COPER := "INCLUSAO4"
            Else
               ZZS->(RecLock("ZZS",.F.))//ALTERADO1
               _COPER := "ALTERADO1"//"ALTERADO-FINAL"
            EndIf

            ZZS->ZZS_COD	:= aCols[_l,nPosProd]
            ZZS->ZZS_DESCR	:= aCols[_l,nPosDesc]
            ZZS->ZZS_DESCD	:= aCols[_l,nPosDesD]
            ZZS->ZZS_UM		:= aCols[_l,nPosUM]
            ZZS->ZZS_QTD   	:= aCols[_l,nPosQtd]
            ZZS->ZZS_2UM	:= aCols[_l,nPos2UM]
            ZZS->ZZS_QTD2UM	:= aCols[_l,nPos2Qtd]
            ZZS->ZZS_3UM    := aCols[_l,nPos3UM ]//Novo
            ZZS->ZZS_QTD3UM := aCols[_l,nPos3Qtd]//Novo
            ZZS->ZZS_VALOR  := aCols[_l,nPosVal ]//Novo
            ZZS->ZZS_TIPOV  := Posicione("SA3",1,FWxfilial("SA3")+cCoord,"A3_I_TIPV")//Novo
            ZZS->(MSUnLock())

            ZGW->(RecLock("ZGW",.T.))//ALTERADO1 / INCLUSAO4
            ZGW->ZGW_FILIAL := FWxfilial("ZGW")
            ZGW->ZGW_COD    := ZZS->ZZS_COD
            ZGW->ZGW_DESCR  := ZZS->ZZS_DESCR
            ZGW->ZGW_DESCD  := ZZS->ZZS_DESCD
            ZGW->ZGW_UM     := ZZS->ZZS_UM
            ZGW->ZGW_QTD   	:= ZZS->ZZS_QTD
            ZGW->ZGW_2UM    := ZZS->ZZS_2UM
            ZGW->ZGW_QTD2UM	:= ZZS->ZZS_QTD2UM
            ZGW->ZGW_3UM    := ZZS->ZZS_3UM   //Novo
            ZGW->ZGW_QTD3UM := ZZS->ZZS_QTD3UM//Novo
            ZGW->ZGW_VALOR  := ZZS->ZZS_VALOR //Novo
            ZGW->ZGW_TIPOV  := ZZS->ZZS_TIPOV //Novo
            ZGW->ZGW_DATAM  := ZZS->ZZS_DATA  //Novo
            ZGW->ZGW_COOR   := ZZS->ZZS_COOR
            ZGW->ZGW_NMCOOR := ZZS->ZZS_NMCOOR
            ZGW->ZGW_ANOMES := ZZS->ZZS_ANOMES
            ZGW->ZGW_OPER   := _COPER
            ZGW->ZGW_USER   := _cUserName
            ZGW->ZGW_DATA   := Date()
            ZGW->ZGW_HORA   := Time()
            ZGW->(MSUnLock())
            lGravouDados:=.T.

            AOMS063Ger("GERAR_VALORES_POR_DATA",ZZS->ZZS_ANOMES)

        Else//EXCLUSAO

            If ZZS->(MSSeek(FWxfilial("ZZS")+cAnoMes+cCoord+aCols[_l,nPosProd]+"      "))
               ZGW->(RecLock("ZGW",.T.))//EXCLUSAO_LINHA_PRODUTO
               ZGW->ZGW_FILIAL := FWxfilial("ZGW")
               ZGW->ZGW_COD    := ZZS->ZZS_COD
               ZGW->ZGW_DESCR  := ZZS->ZZS_DESCR
               ZGW->ZGW_DESCD  := ZZS->ZZS_DESCD
               ZGW->ZGW_UM     := ZZS->ZZS_UM
               ZGW->ZGW_QTD    := ZZS->ZZS_QTD
               ZGW->ZGW_QTD2UM := ZZS->ZZS_QTD2UM
               ZGW->ZGW_2UM    := ZZS->ZZS_2UM
               ZGW->ZGW_QTD3UM := ZZS->ZZS_QTD3UM//Novo
               ZGW->ZGW_3UM    := ZZS->ZZS_3UM   //Novo
               ZGW->ZGW_VALOR  := ZZS->ZZS_VALOR //Novo
               ZGW->ZGW_TIPOV  := ZZS->ZZS_TIPOV //Novo
               ZGW->ZGW_DATAM  := ZZS->ZZS_DATA  //Novo
               ZGW->ZGW_COOR   := ZZS->ZZS_COOR
               ZGW->ZGW_NMCOOR := ZZS->ZZS_NMCOOR
               ZGW->ZGW_ANOMES := ZZS->ZZS_ANOMES
               ZGW->ZGW_OPER   := "EXCLUSAO_LINHA_PRODUTO"
               ZGW->ZGW_USER   := _cUserName
               ZGW->ZGW_DATA   := Date()
               ZGW->ZGW_HORA   := Time()
               ZGW->(MSUnLock())

               AOMS063Ger("EXCLUIR_VALORES_POR_DATA")

               ZZS->(RecLock("ZZS",.F.))//EXCLUSAO_LINHA_PRODUTO
               ZZS->(dbDelete())
               ZZS->(MSUnLock())
               lGravouDados:=.T.

            EndIf
        EndIf
    Next _l

 EndIf

 If lGravouDados
    U_ITMsg("Alteração Concluida Com Sucesso","Atenção",,2)
    //cChama = "RECARREGA" Não precisa recarregar na alteração
    oDlgLIb:End()
 EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS063N
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Exclusão Cadastro de Previsão de Vendas
Parametros--------: oProc - objeto de processamento
                    _nOpcao - 1 - Exclui todos os coordenadores
                              2 - Exclui apenas o coordenador selecionado
                              3 - Cancela a exclusão
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063N(oProc As Object)

 Local _nOpcao:= 0 As Numeric
 Local cAno   := SubStr(TMP->ANOMES,5,2)+"-"+SubStr(TMP->ANOMES,1,4) As Char// Mes/Ano  As Char
 Local cCoo   := TMP->COORD  As Char
 Local cCooD  := AllTrim(TMP->NMCOORD) As Char

 _nOpcao:=AVISO("AOMS063N - Exclusão de Metas de Vendas","Deseja Excluir As metas do Mes: "+cAno+" todo de todos os coordenadores ou somente As metas do Coord/Vend: "+cCoo+" - "+cCooD,;
               {"SIM p/ Mes"        ,;   // 01
                "SIM p/ Coordenador",;   // 02
                "Cancelar"        },2)   // 03

 cChama := "NÃO RECARREGAR" //Se Cancelou

 If _nOpcao <> 3// Se não Cancelou
     _nCont:=0
     lGravouDados:=.F.
     ZZS->(DBSetOrder(4))
     ZZS->(MSSeek(FWxfilial("ZZS")+TMP->ANOMES+If(_nOpcao=2,TMP->COORD,"")))

     While !ZZS->(Eof()) .And. TMP->ANOMES == ZZS->ZZS_ANOMES .And. If(_nOpcao=2,(TMP->COORD == ZZS->ZZS_COOR),.T.)

         _nCont++
         oProc:cCaption := ( "Excluindo metas: " + StrZero(_nCont,6)+" - Data: "+DToC(ZZS->ZZS_DATA)  )
         ProcessMessages()

         ZGW->(RecLock("ZGW",.T.))//EXCLUSAO_Mes-Ano_Coord/Vend - EXCLUSAO_Mes-Ano
         ZGW->ZGW_FILIAL:= FWxfilial("ZGW")
         ZGW->ZGW_COD   := ZZS->ZZS_COD
         ZGW->ZGW_DESCR	:= ZZS->ZZS_DESCR
         ZGW->ZGW_DESCD	:= ZZS->ZZS_DESCD
         ZGW->ZGW_UM	:= ZZS->ZZS_UM
         ZGW->ZGW_QTD   := ZZS->ZZS_QTD
         ZGW->ZGW_2UM   := ZZS->ZZS_2UM
         ZGW->ZGW_QTD2UM:= ZZS->ZZS_QTD2UM
         ZGW->ZGW_3UM   := ZZS->ZZS_3UM   //Novo
         ZGW->ZGW_QTD3UM:= ZZS->ZZS_QTD3UM//Novo
         ZGW->ZGW_VALOR := ZZS->ZZS_VALOR //Novo
         ZGW->ZGW_TIPOV := ZZS->ZZS_TIPOV //Novo
         ZGW->ZGW_DATAM := ZZS->ZZS_DATA  //Novo
         ZGW->ZGW_COOR  := ZZS->ZZS_COOR
         ZGW->ZGW_NMCOOR:= ZZS->ZZS_NMCOOR
         ZGW->ZGW_ANOMES:= ZZS->ZZS_ANOMES
         ZGW->ZGW_OPER  := If(_nOpcao=2,"EXCLUSAO_Mes-Ano_Coord/Vend","EXCLUSAO_Mes-Ano")
         ZGW->ZGW_USER  := _cUserName
         ZGW->ZGW_DATA  := Date()
         ZGW->ZGW_HORA  := Time()
         ZGW->(MSUnLock())

         lGravouDados:=.T.

         ZZS->(RecLock("ZZS",.F.))//EXCLUSAO_Mes-Ano_Coord/Vend - EXCLUSAO_Mes-Ano
         ZZS->(DbDelete())
         ZZS->(MSUnLock())

        ZZS->(DBSkip())
     EndDo

     If _nOpcao=2
         TMP->(DbDelete())   //Atual
         TMP->(DBSkip())     //VAI PARA O PROXIMO
         If TMP->(Eof())     //SE Eof()
            TMP->(DBSkip(-1))//VOLTA UM
         EndIf
         U_ITMsg("Mes-Ano: "+cAno+" do Coord/Vend: "+cCoo+" - "+cCooD+" Excluida Com Sucesso","Atenção",,2)
         oMark:oBrowse:Refresh(.T.)

     Else
         U_ITMsg("Mes-Ano: "+cAno+" Excluido Com Sucesso","Atenção",,2)
         cChama := "RECARREGA" //Reinicia tela
         oDlgLIb:End()
     EndIf

 EndIf

Return


/*
===============================================================================================================================
Programa----------: AOMS063B
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Valida produtos
Parametros--------: Nenhum
Retorno-----------: lRet - True se emcontro produtos
===============================================================================================================================
*/
Static Function AOMS063B() As Logical
 Local I As Numeric
 Local nPosProd := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'} ) As Numeric
  For I:= 1 to Len(aCols)
     If !Empty(aCols[I,nPosProd]) .And. !Atail(aCols[I])
         Return .F.
     EndIf
 Next I
Return .T.

/*
===============================================================================================================================
Programa----------: AOMS063U
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/13
Descrição---------: Prepara variáveis e dados
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063U(oProc As Object)
 Local _cAlias:=GetNextAlias() As Char
 Local cQuery := " SELECT ZZS.ZZS_COOR COORD, ZZS.ZZS_NMCOOR NMCOORD, ZZS.ZZS_ANOMES ANOMES " As Char
 cQuery += " FROM ZZS010 ZZS "
 cQuery += " WHERE ZZS_FILIAL = '"+FWxfilial("ZZS")+"' "
 cQuery += " AND D_E_L_E_T_ = ' ' "
 If Len(_cAnoIni) = 4
    cQuery += " AND SubStr(ZZS.ZZS_ANOMES,1,4) >= '" + _cAnoIni+"' "
 ElseIf !Empty(_cAnoIni)
    cQuery += " AND ZZS.ZZS_ANOMES >= '" + _cAnoIni+"' "
 EndIf
 If Len(_cAnoFim) = 4
    cQuery += " AND SubStr(ZZS.ZZS_ANOMES,1,4) >= '" + _cAnoFim+"' "
 ElseIf !Empty(_cAnoFim)
    cQuery += " AND ZZS.ZZS_ANOMES <= '" + _cAnoFim+"' "
 EndIf
 cQuery += " GROUP BY ZZS.ZZS_COOR, ZZS_NMCOOR, ZZS.ZZS_ANOMES "

 MPSysOpenQuery( cQuery , _cAlias)

 aCpoTmp:={}
 AAdd(aCpoTmp,{"ANOMES" ,"C",06,0})
 AAdd(aCpoTmp,{"COORD"  ,"C",06,0})
 AAdd(aCpoTmp,{"NMCOORD","C",60,0})
 AAdd(aCpoTmp,{"TIPO"   ,"C",40,0})
 AAdd(aCpoTmp,{"BLOQ"   ,"C",03,0})

 If Select("TMP") > 0 .And. Type("_oTemp") == "O"
     _oTemp:Delete()
 EndIf

 _oTemp := FWTemporaryTable():New( "TMP", aCpoTmp )
 _oTemp:AddIndex( "01", {"ANOMES","NMCOORD"} )
 _oTemp:AddIndex( "02", {"COORD","ANOMES"  } )
 _oTemp:AddIndex( "03", {"NMCOORD"}          )

 _oTemp:Create()

 _nCont:=0
 _cReg:=0
 DBSelectArea(_cAlias)
  COUNT TO _cReg
 _cReg:=AllTrim(Str(_cReg))
 (_cAlias)->(DBGoTop())

 While !(_cAlias)->(Eof())

     _nCont++
     oProc:cCaption := ( "Lendo Metas: " + StrZero(_nCont,5) + " de " + _cReg)
     ProcessMessages()

     cTipoor     := Posicione("SA3",1,FWxfilial("SA3")+(_cAlias)->COORD,"A3_I_TIPV")//V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR;N=GERENCIA NACIONAL
     If cTipoor == "V"
         cTipoor := "Vendedor"
     ElseIf cTipoor == "C"
         cTipoor := "Coordenador"
     ElseIf cTipoor == "G"
         cTipoor := "Gerente"
     ElseIf cTipoor == "S"
         cTipoor := "Supervisor"
     ElseIf cTipoor == "N"
         cTipoor := "Gerencia Nacional"
     Else
         cTipoor := "Tipo de Vendedor não encontrado"
     EndIf

     TMP->(DbAppend())
     TMP->COORD  := (_cAlias)->COORD
     TMP->ANOMES := (_cAlias)->ANOMES
     TMP->NMCOORD:= (_cAlias)->NMCOORD
     TMP->TIPO   := cTipoor
     TMP->BLOQ   := If(SA3->A3_MSBLQL = '1', "SIM", "NAO")
     (_cAlias)->(DBSkip())

 EndDo

 (_cAlias)->(DBCloseArea())

 TMP->(DBGoTop())
 aCpoBrw:={}
 AAdd(aCpoBrw,{"ANOMES" ,""	,"Ano - Mes"            ,"@R 9999-99","06","0"})
 AAdd(aCpoBrw,{"COORD"  ,""	,"Codigo"               ,"@!"        ,"06","0"})
 AAdd(aCpoBrw,{"NMCOORD",""	,"Nome"                 ,"@!"        ,"60","0"})
 AAdd(aCpoBrw,{"TIPO"   ,""	,"Tipo"                 ,"@!"        ,"40","0"})
 AAdd(aCpoBrw,{"BLOQ"   ,""	,"Coor.\Vend.Bloqueado?","@!"        ,"20","0"})

Return

/*
===============================================================================================================================
Programa----------: AOMS063K
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/04/2018
Descrição---------: Importa tabela de dados
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063K(oProc As Object)
 Local _aHead    := {}  As Array
 Local _aLinhas  := {}  As Array
 Local _aParAux  := {}  As Array
 Local _aParRet  := {}  As Array
 Local _aErros   := {}  As Array
 Local _aDados   := {}  As Array
 Local I         := 000 As Numeric
 Local _nRep     := 000 As Numeric
 Local _nCont    := 000 As Numeric
 Local _nReg     := 000 As Numeric
 Local _nVolume  := 000 As Numeric
 Local _nValor   := 000 As Numeric
 Local _nPosDados:= 000 As Numeric
 Local nColNome  := 000 As Numeric
 Local nColNprd  := 000 As Numeric
 Local _oFile    := Nil As Object
 Local _cArq     := ""  As Char
 Local _cDados   := ""  As Char
 Local _cErro    := ""  As Char
 Local _cAviso   := ""  As Char
 Local _cValor   := ""  As Char
 Local _cVolume  := ""  As Char
 Local _cCodVend := ""  As Char
 Local _cCodProd := ""  As Char
 Local _cUnidade := ""  As Char

 Private nColVen   := 0 As Numeric
 Private nColPrd   := 0 As Numeric
 Private nColVol   := 0 As Numeric
 Private nColVal   := 0 As Numeric
 Private nColUM    := 0 As Numeric
 Private _nPosAviso:= 0 As Numeric
 Private _nColVolCa  := 0 As Numeric
 Private _nColValCa  := 0 As Numeric

 MV_PAR01 := Space(6)
 MV_PAR02 := Space(200)

 AAdd( _aParAux ,{ 1 ,"Digite o Ano/mes (AAAA-MM)" ,MV_PAR01,"@R 9999-99","",""   ,"" ,015 ,.T. } )
 AAdd( _aParAux ,{ 1 ,"Selecione arquivo de ajuste",MV_PAR02,"@!"        ,"","DIR","" ,100 ,.T. } )

 For I := 1 To Len( _aParAux )
     AAdd( _aParRet ,_aParAux[I][03] )
 Next I

 //aParametros,cTitle                                   ,@aRet    ,[bOk]  ,[ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ]
 If !ParamBox( _aParAux ,"Selecione o Arquivo .CSV para Importar" ,@_aParRet,       ,/*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
     Return
 EndIf

 _cArq  := AllTrim(MV_PAR02)
 _oFile := FwFileReader():New(_cArq)

 If !_oFile:Open()
     U_ITMsg("1-Falha ao abrir o arquivo: "+_cArq,"Erro",,1)
     Return
 EndIf

 oProc:cCaption := ( "Lendo Dados: "+ _cArq )
 ProcessMessages()

 _cDados := _oFile:GetLine()

 //Verifica segunda linha de headers
 If !"REGIONAL;COOR.;COD. COOR.;MIX;" $ AllTrim(_cDados) .And. !"REGIONAL;VEND.;COD. VENDEDOR;MIX;" $ AllTrim(_cDados)
     U_ITMsg("Arquivo não está no layout de metas de venda","Atenção",;
             "Layout necessario: REGIONAL;COOR. ou VEND.;COD. COOR. ou VENDEDOR;MIX;FAMILIA;GRUPO - AJUSTADO;CODIGO;PRODUTO;VOLUME;UNI. VOL;VALOR (R$)",1)
     Return
 EndIf

 _cDados  := AllTrim(_cDados)
 _aHead   := StrTokArr2(_cDados,";",.T.) //_aHead:={REGIONAL;COOR.;COD. COOR.;MIX;FAMILIA;GRUPO - AJUSTADO;CODIGO;PRODUTO;VOLUME;UNI. VOL;VALOR (R$);ANOMES}
 _aHead[1]:= "ANO/MES"
 nColVen  := AScan(_aHead,"COD. "     ) //DO VENDEDOR OU COORDENADOR
 nColPrd  := AScan(_aHead,"CODIGO"    ) //CODIGO DO PRODUTO
 nColVol  := AScan(_aHead,"VOLUME"    ) //QUANTIDADE
 nColVal  := AScan(_aHead,"VALOR (R$)") //VALOR EM Real
 nColUM   := AScan(_aHead,"UNI. VOL"  ) //UNIDADE DE MEDIDA

 If nColVen=0 .Or. nColPrd=0 .Or. nColVol=0 .Or. nColVal=0
     U_ITMsg("Arquivo não está no layout de metas de venda","Atenção",'Um desses nomes de campo não esta no arquivo: "COD. ", "CODIGO" , "VOLUME", "UNI. VOL" ou "VALOR (R$)"',1)
     Return
 EndIf

 nColNome:=nColVen-1//coluna do nome do vendedor/coordenador
 nColNprd:=nColPrd+1//coluna do nome do vendedor/coordenador

 _aRegs := {}
 LjMsgRun( "Lendo Arq: "+_cArq , TIME()+" - Aguarde..." , {|| _aRegs := _oFile:getAllLines() } )

 _nReg:= Len(_aRegs)

 If _nReg == 0 //O arquivo informado nao possui nenhuma linha de dados
    U_ITMsg("O arquivo informado para relizar a importação não possui dados.",;
            "Arquivo inválido",;
            "Favor verificar se o arquivo "+_cArq+" informado esta no formato correto.")
    Return
 EndIf
 _nCont := 0
 _aErros:= {}
 _aDados:= {}
 _aSomaDuplic:= {}
 SB1->(DBSetOrder(1))
 SA3->(DBSetOrder(1))

 _aCab := {}
 AAdd(_aCab," ")//COLUNA DAS BOLINHAS VERMELHA E VERDE
 For _nRep := 1 to Len(_aHead)
     AAdd(_aCab,_aHead[_nRep])
 Next _nRep
 AAdd(_aCab,"Erros")//COLUNA DOS ERROS
 AAdd(_aCab,"Observações")//COLUNA DOS Avisos

 _nPosAviso:= Len(_aCab)               
 _nColVolCa:= AScan(_aCab,"VOLUME"    )
 _nColValCa:= AScan(_aCab,"VALOR (R$)")

 //While (_oFile:hasLine()) // É LENTO
 For I := 1 To Len(_aRegs)

     _nCont++
     oProc:cCaption := ( "1/1 - Lendo / Validando linha " + StrZero(_nCont,6) + " de " + StrZero(_nReg,6) + ". Erros: "+StrZero(Len(_aErros),6) )
     ProcessMessages()

     _cErro :=""//para cada linha Limpa
     _cAviso:=""//para cada linha Limpa
     _cDados:= _aRegs[I]//AllTrim(_oFile:GetLine()) // É LENTO

     AAdd(_aLinhas,StrTokArr2(_cDados,";",.T.))

     _nI:= Len(_aLinhas)

     Begin Sequence

         If Len(_aLinhas[_nI]) < Len(_aHead)
            _cErro += "[Linha " + StrZero(_nI,6) + " com divergência de colunas, verifique se todos As metas contém valores numéricos, em caso de meta zerada deve estar com número 0.] "
            If Len(_aLinhas[_nI]) < nColVal
               _nPosDados = 0
               BREAK
            EndIf
         EndIf

         //Normaliza campos de código
         _aLinhas[_nI][1]      := SubStr(MV_PAR01,5,2)+"/"+SubStr(MV_PAR01,1,4) // Mes/Ano
         _aLinhas[_nI][nColPrd]:= StrZero(Val(_aLinhas[_nI][nColPrd]),11)

         //NORMALIZA CAMPOS DE VALORES PARA NUMÉRICO
         _cVolume:=(StrTran(_aLinhas[_nI][nColVol],"." ,"" ))//Remove ponto
         _cVolume:=(StrTran(_cVolume,"," ,"."))//Troca virgula por ponto das decimais

         _aLinhas[_nI][nColVol]:=  Val(_cVolume) //VOLUME
         _nVolume              := _aLinhas[_nI][nColVol]

         _cValor:=AllTrim(StrTran(_aLinhas[_nI][nColVal],"R$",""))//Remove R$
         _cValor:=(StrTran(_cValor,"." ,"" ))//Remove ponto
         _cValor:=(StrTran(_cValor,"," ,"."))//Troca virgula por ponto das decimais

         _aLinhas[_nI][nColVal]:= Val(_cValor) //VALOR
         _nValor               := Val(_cValor)

         _cCodVend:=_aLinhas[_nI][nColVen]
         _cCodProd:=U_ITKey(_aLinhas[_nI][nColPrd],"ZZS_COD")
         _cUnidade:=Upper(AllTrim(_aLinhas[_nI][nColUM]))
         _lProd := .T.
         If SB1->(MSSeek(FWxfilial("SB1")+_cCodProd))
            If SB1->B1_MSBLQL == '1'
                 //_lProd := .F.
                 _cAviso += '[Cod. Produto "'+AllTrim(_cCodProd)+'" Bloqueado] '
            ElseIf AllTrim(SB1->B1_UM) <> _cUnidade .And. AllTrim(SB1->B1_SEGUM) <> _cUnidade .And.  AllTrim(SB1->B1_I_3UM) <> _cUnidade
                 _lProd := .F.
                 _cErro += '[UM "'+_cUnidade+'" do Produto "'+AllTrim(_cCodProd)+'" Invalida, 1UM: "'+SB1->B1_UM+'", 2UM: "'+SB1->B1_SEGUM+'", 3UM: "'+SB1->B1_I_3UM+'".] '
             EndIf
         Else
             _cErro += '[Cod. Produto "'+(_cCodProd)+'"  não encontrado] '
         EndIf

         _lVend := .T.
         If SA3->(MSSeek(FWxfilial("SA3")+_cCodVend))
             _cNome := AllTrim(SA3->A3_NOME)
             If SA3->A3_MSBLQL == '1'
                 //_lVend := .F.
                 _cAviso += '[Cod. Vendedor "'+_cCodVend+'"-'+_cNome+" Bloqueado] "
             EndIf
         Else
             _cNome := AllTrim(_aLinhas[_nI][nColNome])
             _cErro += '[Cod. Vendedor "'+_cCodVend+'"-'+_cNome+" não encontrado] "
             _lVend := .F.
         EndIf

     _aLinAux  := {}
     _nLinAtual:= Len(_aLinhas)//LINHA DO _aLinhas no momento
     _nPosDados:= 0

     _nPos:=AScan(_aSomaDuplic ,{ |x| x[1] == _cCodProd+_cCodVend } )//Procura se já existe essa combinação
     If _nPos = 0 .And. _lProd .And. _lVend
        AAdd(_aSomaDuplic,{_cCodProd+_cCodVend,;//01
                           Len(_aDados)+1,;     //02 - Soma mais 1 pq ele ainda não foi adicionado, mas vai ser com certeza
                           _nVolume,;           //03
                           _nValor,;            //04
                           " Soma das linhas duplicadas: (Volume: "+AllTrim(Str(_nVolume,15,3))+" "+_cUnidade+", Valor: "+AllTrim(Str(_nValor,15,2))+")",;//05
                           _cUnidade})          //06
     ElseIf _nPos > 0 .And. _lProd .And. _lVend

         If _cUnidade <> _aSomaDuplic[_nPos,6]
            //Carrega fator de conversão se existir
            _nVolume := AOMS063Conv(_nVolume,_cUnidade,_aSomaDuplic[_nPos,6],0,0,0)//CONVERTE PARA 1UM, 2UM E 3UM
            _aSomaDuplic[_nPos,5] := _aSomaDuplic[_nPos,5]+" (Volume : "+AllTrim(Str(_nVolume,15,3))+" "+_aSomaDuplic[_nPos,6]+", convertido de "+_cUnidade+", Valor: "+AllTrim(Str(_nValor,15,2))+")"
         Else
            _aSomaDuplic[_nPos,5] := _aSomaDuplic[_nPos,5]+" (Volume: "+AllTrim(Str(_nVolume,15,3))+" "+_cUnidade+", Valor: "+AllTrim(Str(_nValor,15,2))+")"
         EndIf

        _aSomaDuplic[_nPos,3] += _nVolume    //Soma os duplicados
        _aSomaDuplic[_nPos,4] += _nValor     //Soma os duplicados
        _nPosDados:= _aSomaDuplic[_nPos,2]  //Recupera a linha que já existe
        _nVolume  := _aSomaDuplic[_nPos,3]
        _nValor   := _aSomaDuplic[_nPos,4]
        _cAviso   := _aSomaDuplic[_nPos,5]
     EndIf

     If !Empty(_cErro) .Or. !Empty(_cAviso)
        If !Empty(_cErro)
           _cErro:="Linha " + StrZero(_nI,6) + " com erro(s): "+ _cErro
        EndIf
        If !Empty(_cAviso)
           _cAviso:="Linha " + StrZero(_nI,6) + " com aviso(s): "+ _cAviso
        EndIf
        AAdd(_aErros,{Empty(_cErro),_cErro,_cAviso})
     EndIf

     End Sequence

     If _nPosDados = 0
        AAdd(_aLinAux,Empty(_cErro))//COLUNA DAS BOLINHAS VERMELHA E VERDE
        For _nRep := 1 to Len(_aHead)//TODAS As COLUNAS DO _aLinhas
            If _nRep <= Len(_aLinhas[_nLinAtual])
                AAdd(_aLinAux,_aLinhas[_nLinAtual,_nRep])
            Else
                AAdd(_aLinAux,"")
            EndIf
        Next _nRep
        AAdd(_aLinAux, _cErro )//COLUNA DOS ERROS
        AAdd(_aLinAux, _cAviso)//COLUNA DE AVISOS

        AAdd(_aDados,_aLinAux)
    Else
        _aDados[_nPosDados][_nColVolCa] := _nVolume    //Grava a Soma dos duplicados
        _aDados[_nPosDados][_nColValCa] := _nValor     //Grava a Soma dos duplicados
        _aDados[_nPosDados][_nPosAviso] := _cAviso
    EndIf

 Next I

 _oFile:Close()

 If Len(_aDados) > 0

     _aLegenda := {{ "BR_VERDE", "Aceitos"},{"BR_VERMELHO","Rejeitados"} }
     _aButtons:={}
     AAdd(_aButtons,{"",{|| BRWLEGENDA( "Legenda", "Legenda", _aLegenda ) },"","Legenda"} )

    _cMsgTop := 'PARA REALIZAR A GRAVAÇÃO DAS METAS DE VENDAS ACEITAS ABAIXO CLIQUE EM "CONFIRMAR"'
    If Len(_aErros) > 0
       _cMsgTop += " - Para ver a lista dos "+AllTrim(Str(Len(_aErros)))+' Erros, clique em "Outras Açoões" e depois clique em "Erros" '
       AAdd(_aButtons,{"",{|| U_ITListBox("Erros e Avisos: "+AllTrim(Str(Len(_aErros))),{"","Erros","Avisos"},_aErros,,4) },"","Erros"} )
    EndIf

         //ITListBox( _cTitAux                   ,_aHeader, _aCols , _lMaxSiz,_nTipo, _cMsgTop, _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _aButtons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk,_aSX1,_lComCab)
     If  U_ITListBox( 'Ajuste de meta de vendas' , _aCab  , _aDados, .T.     , 4    , _cMsgTop,          ,         ,         ,     ,        , _aButtons)
         _aLinhas := {}
         For _nRep := 1 to Len(_aDados)
             If _aDados[_nRep][1]
                 aDel(_aDados[_nRep],1)//Remove a primeira coluna
                 AAdd(_aLinhas,_aDados[_nRep])
             EndIf
         Next _nRep
         lGravouDados:=.T.
         FWMsgRun( ,{|oProc| _aAlias := AOMS063A(_aLinhas,_aHead,oProc) } , 'Aguarde!' , 'Importando metas...' )
     EndIf
 EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS063A
Autor-----------: Josué Danich Prestes
Data da Criacao-: 29/03/2018
Descrição-------: Ajusta metas de vendas
Parametros------: _aLista - dados
                  _aHead - cabecalho
                  oProc As Object - objeto de processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063A(_aLista As Array,_aHead As Array,oProc As Object)
 Local _nI       := 0 As Numeric
 Local _aErros   := {} As Array
 Local _cprod    := "N/C" As char
 Local _cvend    := "N/C" As char
 Local aVend     := {} As Array
 Local nAlterados:= 0 As Numeric
 Local _nOpcao   := 0 As Numeric
 Local _nQtde1um := 0 As Numeric
 Local _nQtde2um := 0 As Numeric
 Local _nQtde3um := 0 As Numeric
 Local _nCont    := 0 As Numeric
 Local _cReg:=AllTrim(Str(Len(_aLista))) As Char
 Local _aAlterados := {} As Char
 
 SA3->(DBSetOrder(1))
 ZZS->(DBSetOrder(6))//ZZS_FILIAL+ZZS_ANOMES+ZZS_COD+ZZS_COOR

 For _nI := 1 to Len(_aLista)

     _nCont++
     oProc:cCaption := ( "1/2 - Verificando Metas: " + StrZero(_nCont,5) + " de " + _cReg + ". Alterações: "+StrZero((nAlterados),6) )
     ProcessMessages()
     _cCodVend:=_aLista[_nI][nColVen]
     _cCodProd:=U_ITKey(_aLista[_nI][nColPrd],"ZZS_COD")

     //Procura se existe o produto e vendedor e deleta
     If (ZZS->(MSSeek(FWxfilial("ZZS")+AllTrim(MV_PAR01)+_cCodProd+_cCodVend ) ))

         If _nOpcao = 2 // "NÃO" - ENQUANTO O CODIGO DO VENDEDOR ESTIVER NA TABELA aVend Loop SEM PERGUNTAR
             If AScan(aVend,AllTrim(ZZS->ZZS_COOR)) > 0
                 Loop // *** Loop *** //
             Else
                 _nOpcao = 0 //PERGUNTO DE NOVO NO PROXIMO VEDENDOR
             EndIf

         ElseIf _nOpcao = 3 // "SIM" - ENQUANTO O CODIGO DO VENDEDOR ESTIVER NA TABELA aVend GRAVA A LINHA SEM PERGUNTAR
             If AScan(aVend,AllTrim(ZZS->ZZS_COOR)) = 0
                 _nOpcao = 0 //PERGUNTO DE NOVO NO PROXIMO VEDENDOR
             EndIf

         EndIf

         If _nOpcao = 0 //PERGUNTAR
           _nOpcao:=AVISO("AOMS063A - Todos os dados das Metas serão sobrescritos pelos dados da tabela desse vendedor.","Já Existem dados gravados para o mês "+MV_PAR01+" do vendedor "+ZZS->ZZS_COOR+'-'+AllTrim(ZZS->ZZS_NMCOOR)+" importado, sobscrever?",;
                         {"SIM p/ Todos",;   // 01
                          "NÃO"         ,;   // 02
                          "SIM"         ,;   // 03
                          "NÃO p/ Todos"} ,2)// 04
         EndIf

         If AScan(aVend,AllTrim(ZZS->ZZS_COOR)) = 0
            AAdd(aVend,AllTrim(ZZS->ZZS_COOR))
         EndIf

         If _nOpcao = 4 // "NÃO p/ Todos" - Sair do For
             U_ITMsg("Serão somente processadas As metas não existentes e ACEITAS de todos os vendedores/coordenadores dessa integração para o periodo selecionado.","Atenção",,3)
             Exit //*** SAIR DO For ***//
         ElseIf _nOpcao = 2// "NÃO" - 1o Loop DO "NÃO"
             Loop // *** Loop *** //
         EndIf

         AAdd(_aAlterados,ZZS->(Recno()))
         nAlterados++

     EndIf

 Next _nI

 _nI:=0
 nGravados:=0
 _nErros:=0
 lGravouDados:=.F.
 SB1->(DBSetOrder(1))
 ZZS->(DBSetOrder(6))//ZZS_FILIAL+ZZS_ANOMES+ZZS_COD+ZZS_COOR
 _nCont:=0
 _aErros:={}
 _cReg:=AllTrim(Str(Len(_aLista)))

 For _nI := 1 to Len(_aLista)

     _nCont++
     oProc:cCaption := ( "2/2 - Incluindo Metas: " + StrZero(_nCont,5) + " de " + _cReg + ". Erros: "+StrZero(_nErros,6) )
     ProcessMessages()

     _cCodVend:=_aLista[_nI][nColVen]
     _cCodProd:=U_ITKey(_aLista[_nI][nColPrd],"ZZS_COD")
     _cUnidade:=Upper(AllTrim(_aLista[_nI][nColUM]))
     _cErro   :=""

     _lProd := .T.
     If SB1->(MSSeek(FWxfilial("SB1")+_cCodProd))
         _cprod := AllTrim(SB1->B1_DESC)
         //If SB1->B1_MSBLQL == '1'
         //    //_lProd := .F.
         //    _cErro += '[Cod. Produto "'+_cCodProd+'" Bloqueado] '
         If AllTrim(SB1->B1_UM) <> _cUnidade .And. AllTrim(SB1->B1_SEGUM) <> _cUnidade .And.  AllTrim(SB1->B1_I_3UM) <> _cUnidade
             _lProd := .F.
             _cErro += '[UM "'+_cUnidade+'" do Produto "'+_cCodProd+'" Invalida, 1UM: "'+SB1->B1_UM+'", 2UM: "'+SB1->B1_SEGUM+'", 3UM: "'+SB1->B1_I_3UM+'".] '
         EndIf
     Else
         _cErro += '[Cod. Produto "'+_cCodProd+'"  não encontrado] '
         _lProd := .F.
         _cprod := "N/C "+_aLista[_nI][nColNprd]
     EndIf

     _lVend := .T.
     If SA3->(MSSeek(FWxfilial("SA3")+_cCodVend))
         _cvend := AllTrim(SA3->A3_NOME)
         //If SA3->A3_MSBLQL == '1'
         //    //_lVend := .F.
         //    _cErro += '[Cod. Vendedor "'+_cCodVend+'"-'+_cvend+" Bloqueado] "
         //EndIf
     Else
         _cErro += '[Cod. Vendedor "'+_cCodVend+'"-'+_cvend+" não encontrado] "
         _lVend := .F.
         _cvend := "N/C "+_aLista[_nI][nColNome]
     EndIf

     If !_lProd .Or. !_lVend
        _nErros++
        AAdd(_aErros,{.F.,_aLista[_nI][1],;
                      _cCodVend,_cvend,;
                      _cCodProd,_cprod,;
                      _aLista[_nI][nColVol],;
                      _cUnidade, 0,;
                      SB1->B1_UM,0,;
                      SB1->B1_SEGUM,0,;
                      SB1->B1_I_3UM,;
                      _aLista[_nI][nColVal],;
                      _cErro})
     Else

         //Procura se existe o produto e Coord/vendedor, e inclui se não achar, e altera se achar
         _lAchouAlt:=(ZZS->(MSSeek(FWxfilial("ZZS")+AllTrim(MV_PAR01)+_cCodProd+_cCodVend+"   ") ))
         If _lAchouAlt
            _lAchou:=AScan(_aAlterados,ZZS->(Recno())) > 0//Se achou na lista de alterados, altera, senão não faz nada
         Else
            _lAchou:=.F.
         EndIf
         If !_lAchouAlt .Or. _lAchou//SE NÃO ACHOU OU ACHOU NA LISTA DE ALTERADOS

             //Carrega fator de conversão se existir
             _nQtde1um:=0
             _nQtde2um:=0
             _nQtde3um:=0
             AOMS063Conv(_aLista[_nI][nColVol],_cUnidade,"",@_nQtde1um,@_nQtde2um,@_nQtde3um)//CONVERTE PARA 1UM, 2UM E 3UM

             AAdd(_aErros,{.T.,_aLista[_nI][1],;
                           _cCodVend,_cvend,;
                           _cCodProd,_cprod,;
                           _aLista[_nI][nColVol],;
                           _cUnidade,;
                           _nQtde1um,SB1->B1_UM,;
                           _nQtde2um,SB1->B1_SEGUM,;
                           _nQtde3um,SB1->B1_I_3UM,;
                           _aLista[_nI][nColVal],;
                           If(_lAchou,"Alterado com sucesso","Incluido com sucesso")})

             ZZS->(RecLock("ZZS",!_lAchou))//"ALTERACAO/IMPORTACAO","INCLUSAO/IMPORTACAO"
             ZZS->ZZS_COD    := SB1->B1_COD
             ZZS->ZZS_DESCR  := SB1->B1_DESC
             ZZS->ZZS_DESCD  := SB1->B1_I_DESCD
             ZZS->ZZS_UM     := SB1->B1_UM
             ZZS->ZZS_2UM    := SB1->B1_SEGUM
             ZZS->ZZS_3UM    := SB1->B1_I_3UM        //Novo
             ZZS->ZZS_COOR   := SA3->A3_COD
             ZZS->ZZS_NMCOOR := SA3->A3_NOME
             ZZS->ZZS_ANOMES := MV_PAR01
             ZZS->ZZS_QTD    := _nQtde1um
             ZZS->ZZS_QTD2UM := _nQtde2um
             ZZS->ZZS_QTD3UM := _nQtde3um            //Novo
             ZZS->ZZS_VALOR  := _aLista[_nI][nColVal]//Novo
             ZZS->ZZS_TIPOV  := SA3->A3_I_TIPV       //Novo
             ZZS->(MSUnLock())

             ZGW->(RecLock("ZGW",.T.))//"ALTERACAO/IMPORTACAO","INCLUSAO/IMPORTACAO"
             ZGW->ZGW_FILIAL:= FWxfilial("ZGW")
             ZGW->ZGW_COD   := ZZS->ZZS_COD
             ZGW->ZGW_DESCR := ZZS->ZZS_DESCR
             ZGW->ZGW_DESCD := ZZS->ZZS_DESCD
             ZGW->ZGW_UM    := ZZS->ZZS_UM
             ZGW->ZGW_QTD   := ZZS->ZZS_QTD
             ZGW->ZGW_QTD2UM:= ZZS->ZZS_QTD2UM
             ZGW->ZGW_2UM   := ZZS->ZZS_2UM
             ZGW->ZGW_QTD3UM:= ZZS->ZZS_QTD3UM//Novo
             ZGW->ZGW_3UM   := ZZS->ZZS_3UM   //Novo
             ZGW->ZGW_VALOR := ZZS->ZZS_VALOR //Novo
             ZGW->ZGW_TIPOV := ZZS->ZZS_TIPOV //Novo
             ZGW->ZGW_DATAM := ZZS->ZZS_DATA  //Novo
             ZGW->ZGW_COOR  := ZZS->ZZS_COOR
             ZGW->ZGW_NMCOOR:= ZZS->ZZS_NMCOOR
             ZGW->ZGW_ANOMES:= ZZS->ZZS_ANOMES
             ZGW->ZGW_OPER  := If(_lAchou,"ALTERACAO/IMPORTACAO","INCLUSAO/IMPORTACAO")
             ZGW->ZGW_USER  := _cUserName
             ZGW->ZGW_DATA  := Date()
             ZGW->ZGW_HORA  := Time()
             ZGW->(MSUnLock())

             AOMS063Ger("GERAR_VALORES_POR_DATA",ZZS->ZZS_ANOMES)

             nGravados++
             lGravouDados:=.T.
         Else
             _nErros++
             AAdd(_aErros,{.F.,_aLista[_nI][1],;
                           _cCodVend,_cvend,;
                           _cCodProd,_cprod,;
                           _aLista[_nI][nColVol],;
                           _cUnidade,0,;
                           SB1->B1_UM,0,;
                           SB1->B1_SEGUM,0,;
                           SB1->B1_I_3UM,;
                           _aLista[_nI][nColVal],;
                           "Produto já existe na tabela de metas para esse Coor./vend.: "+FWxfilial("ZZS")+" "+AllTrim(MV_PAR01)+" "+_cCodProd+" "+_cCodVend})
         EndIf
     EndIf
 Next _nI

 cChama = "NÃO RECARREGAR"
 If Len(_aErros) > 0
     _aHead2 := {"","Mesano","Cod Vend","Vendedor","Cod Prod","Produto","Volume","Unidade","Qtde 1Um","1Um","Qtde 2Um","2Um","Qtde 3Um","3Um","Valor (R$)","Erros"}
     U_ITListBox( 'Ajuste de meta de vendas' , _aHead2 , _aErros , .T. , 4, "Vendedor(es): Gravados "+AllTrim(Str(nGravados))+ " / Alterados "+AllTrim(Str(nAlterados))+" / Processados "+_cReg+ " / Erros: "+AllTrim(Str(_nErros)) )
     cChama = "RECARREGA"
     oDlgLIb:End()
 Else
     If lGravouDados
        U_ITMsg("Gravacao Concluida Com Sucesso","Atenção","Vendedor(es): Incluidos "+AllTrim(Str(nGravados))+ " / Alterados "+AllTrim(Str(nAlterados))+" / Processados "+  _cReg ,2)
        cChama = "RECARREGA"
        oDlgLIb:End()
     Else
        U_ITMsg("Nenhum registro Gravado no mes "+AllTrim(MV_PAR01)+". Vendedor(es): Incluidos "+AllTrim(Str(nGravados))+ " / Alterados "+AllTrim(Str(nAlterados))+" / Processados "+  _cReg,"Atenção","Integre em um mês que não tenha metas de ninguem no mês.",2)
     EndIf
 EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS063R
Autor-----------: Josué Danich Prestes
Data da Criacao-: 18/09/2018
Descrição-------: Relatório de log de metas de vendas
Parametros------: _lLog: .T. - Log  / .F. - Relatório
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063R(_lLog As Logical)
 If Pergunte( 'AOMS063R' )
    FWMsgRun(,{|oProc|AOMS063S(oProc,_lLog) } ,'Aguarde!','Lendo dados...' )
 EndIf
Return

/*
===============================================================================================================================
Programa--------: AOMS063S
Autor-----------: Josué Danich Prestes
Data da Criacao-: 18/09/2018
Descrição-------: Execução de Relatório de log de metas de vendas
Parametros------: oProc , _lLog: .T. - Log  / .F. - Relatório
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063S(oProc As Object,_lLog As Logical)

 Local cRep    := "" As Char
 Local _cReg   := "" As Char
 Local _aHead  := {} As Array
 Local _alog   := {} As Array
 Local _cAlias :=GetNextAlias() As Char
 Local _nCont  := 0 As Numeric
 Local A       := 0 As Numeric

 If _lLog
    cRep:= " SELECT ZGW_COD,ZGW_DESCR,ZGW_QTD,ZGW_UM,ZGW_QTD2UM,ZGW_2UM,ZGW_COOR,ZGW_NMCOOR,ZGW_ANOMES,ZGW_OPER,ZGW_USER,ZGW_DATA,ZGW_HORA,"
    cRep+= "        ZGW_QTD3UM,ZGW_3UM,ZGW_VALOR,ZGW_DATAM"//Novos
    cRep+= " FROM " + retsqlname("ZGW")
    cRep+= " WHERE ZGW_ANOMES = '"+AllTrim(MV_PAR01)+"'
    If !Empty(AllTrim(MV_PAR03))
        cRep+= " AND ZGW_COOR >= '"+ (MV_PAR02) + "' AND ZGW_COOR <= '" + (MV_PAR03) + "' "
    EndIf
    If !Empty(AllTrim(MV_PAR05))
        cRep+= " AND ZGW_COD >= '"+ (MV_PAR04) + "' AND ZGW_COD <= '" + (MV_PAR05) + "' ""
    EndIf
    cRep+= " AND D_E_L_E_T_ = ' ' "
    cRep+= " ORDER BY ZGW_ANOMES,ZGW_NMCOOR,ZGW_DESCR,ZGW_DATAM,ZGW_DATA,ZGW_HORA"
    _cTit:='Log de registros de meta de vendas por Produto/Dia'
 Else
    cRep:= " SELECT ZZS_COD,ZZS_DESCR,ZZS_QTD,ZZS_UM,ZZS_QTD2UM,ZZS_2UM,ZZS_COOR,ZZS_NMCOOR,ZZS_ANOMES,"
    cRep+= "        ZZS_QTD3UM,ZZS_3UM,ZZS_VALOR,ZZS_DATA"//Novos
    cRep+= " FROM " + retsqlname("ZZS")
    cRep+= " WHERE ZZS_ANOMES = '"+AllTrim(MV_PAR01)+"'
    If !Empty(AllTrim(MV_PAR03))
        cRep+= " AND ZZS_COOR >= '"+ (MV_PAR02) + "' AND ZZS_COOR <= '" + (MV_PAR03) + "' "
    EndIf
    If !Empty(AllTrim(MV_PAR05))
        cRep+= " AND ZZS_COD >= '"+ (MV_PAR04) + "' AND ZZS_COD <= '" + (MV_PAR05) + "' ""
    EndIf
    cRep+= " AND D_E_L_E_T_ = ' ' "
    cRep+= " ORDER BY ZZS_ANOMES,ZZS_NMCOOR,ZZS_DESCR,ZZS_DATA"
    _cTit:='Relatorio de registros de meta de vendas por Produto/Dia'
 EndIf

 MPSysOpenQuery( cRep , _cAlias)

 _nCont:=0
 _cReg:=0
 DBSelectArea(_cAlias)
  COUNT TO _cReg
 _cReg:=AllTrim(Str(_cReg))
 (_cAlias)->(DBGoTop())

 While (_cAlias)->(!Eof())

     _nCont++
     oProc:cCaption := ( "Lendo Metas: " + StrZero(_nCont,5) + " de " + _cReg)
     ProcessMessages()

     If _lLog
       cTipoor:= Posicione("SA3",1,FWxfilial("SA3")+(_cAlias)->ZGW_COOR,"A3_I_TIPV")//V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR;N=GERENCIA NACIONAL
     Else
       cTipoor:= Posicione("SA3",1,FWxfilial("SA3")+(_cAlias)->ZZS_COOR,"A3_I_TIPV")//V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR;N=GERENCIA NACIONAL
     EndIf
     If cTipoor == "V"
         cTipoor:= "Vendedor"
     ElseIf cTipoor == "C"
         cTipoor:= "Coordenador"
     ElseIf cTipoor == "G"
         cTipoor:= "Gerente"
     ElseIf cTipoor == "S"
         cTipoor:= "Supervisor"
     ElseIf cTipoor == "N"
         cTipoor:= "Gerencia Nacional"
     Else
         cTipoor:= "Tipo de Vendedor não encontrado"
     EndIf

     If _lLog
        AAdd(_alog,{SToD((_cAlias)->ZGW_DATA) ,;//01
                         (_cAlias)->ZGW_HORA  ,;//02
                         (_cAlias)->ZGW_USER  ,;//03
                         (_cAlias)->ZGW_ANOMES,;//04
                         (_cAlias)->ZGW_OPER  ,;//05
                         (_cAlias)->ZGW_COOR  ,;//06
                         (_cAlias)->ZGW_NMCOOR,;//07
                         (_cAlias)->ZGW_COD   ,;//08
                         (_cAlias)->ZGW_DESCR ,;//09
                    SToD((_cAlias)->ZGW_DATAM),;//10
                         (_cAlias)->ZGW_QTD   ,;//11*
                         (_cAlias)->ZGW_UM    ,;//12
                         (_cAlias)->ZGW_QTD2UM,;//13*
                         (_cAlias)->ZGW_2UM   ,;//14
                         (_cAlias)->ZGW_QTD3UM,;//15*
                         (_cAlias)->ZGW_3UM   ,;//16
                         (_cAlias)->ZGW_VALOR ,;//17*
                         cTipoor              })//18
     Else
        AAdd(_alog,{     (_cAlias)->ZZS_ANOMES,;//01
                         (_cAlias)->ZZS_COOR  ,;//02
                         (_cAlias)->ZZS_NMCOOR,;//03
                         (_cAlias)->ZZS_COD   ,;//04
                         (_cAlias)->ZZS_DESCR ,;//05
                    SToD((_cAlias)->ZZS_DATA) ,;//06
                         (_cAlias)->ZZS_QTD   ,;//07*
                         (_cAlias)->ZZS_UM    ,;//08
                         (_cAlias)->ZZS_QTD2UM,;//09*
                         (_cAlias)->ZZS_2UM   ,;//10
                         (_cAlias)->ZZS_QTD3UM,;//11*
                         (_cAlias)->ZZS_3UM   ,;//12
                         (_cAlias)->ZZS_VALOR ,;//13*
                         cTipoor              })//14
     EndIf
     (_cAlias)->(DBSkip())

 EndDo

 //_aColXML:=AClone(_alog)

 For A := 1 TO Len(_alog)
     If _lLog
        _alog[A,11]:= AllTrim(Trans(_alog[A,11],"@E 999,999,999.99"))//11*
        _alog[A,13]:= AllTrim(Trans(_alog[A,13],"@E 999,999,999.99"))//13*
        _alog[A,15]:= AllTrim(Trans(_alog[A,15],"@E 999,999,999.99"))//15*
        _alog[A,17]:= AllTrim(Trans(_alog[A,17],"@E 999,999,999.99"))//17*
    Else
        _alog[A,07]:= AllTrim(Trans(_alog[A,07],"@E 999,999,999.99"))//07*
        _alog[A,09]:= AllTrim(Trans(_alog[A,09],"@E 999,999,999.99"))//09*
        _alog[A,11]:= AllTrim(Trans(_alog[A,11],"@E 999,999,999.99"))//11*
        _alog[A,13]:= AllTrim(Trans(_alog[A,13],"@E 999,999,999.99"))//13*
    EndIf
 Next A

 (_cAlias)->(DBCloseArea())

 If Len(_alog) > 0

    If _lLog
       _aHead:={"Data Manut.",;//01
                "Hora"       ,;//02
                "Usuário"    ,;//03
                "Ano/Mês"    ,;//04
                "Operação"   ,;//05
                "Cod Vend"   ,;//06
                "Vendedor"   ,;//07
                "Cod Prod"   ,;//08
                "Produto"    ,;//09
                "Data Meta"  ,;//10
                "Qtde 1 Um"  ,;//11
                "1a Um"      ,;//12
                "Qtde 2Um"   ,;//13
                "2a Um"      ,;//14
                "Qtde 3Um"   ,;//15
                "3a Um"      ,;//16
                "Valor"      ,;//17
                "Tipo"       } //18
    Else
       _aHead:={"Ano/Mês"    ,;//01
                "Cod Vend"   ,;//02
                "Vendedor"   ,;//03
                "Cod Prod"   ,;//04
                "Produto"    ,;//05
                "Data Meta"  ,;//06
                "Qtde 1 Um"  ,;//07
                "1a Um"      ,;//08
                "Qtde 2Um"   ,;//09
                "2a Um"      ,;//10
                "Qtde 3Um"   ,;//11
                "3a Um"      ,;//12
                "Valor (R$)" ,;//13
                "Tipo"       } //14
    EndIf
     U_ITListBox( _cTit , _aHead , _alog , .T. , 1,  )
 Else
     U_ITMsg("Não foram Localizados registros de log para os parâmetros indicados.","Atenção","Altere os filtros e tente novamente.",1)
 EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS063M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 04/02/2019
Descrição-------: Gatilho para preenchimento dos campos de somente leitura do aCols para a tabela ZZS.
                  Chamado do Valide do campo ZZS_COD
Parametros------: Nenhum
Retorno---------: .T.
===============================================================================================================================
*/
User Function AOMS063M() As Logical
 Local _cCodProd := "" As char
 Local _nPosDesc := 00 As Numeric
 Local _nPosDesD := 00 As Numeric
 Local _nPosUM   := 00 As Numeric
 Local _nPos2UM  := 00 As Numeric
 Local _nPos3UM  := 00 As Numeric
 _cCodProd := M->ZZS_COD
 _nPosDesc := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCR'} )
 _nPosDesD := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_DESCD'} )
 _nPosUM   := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_UM'   } )
 _nPos2UM  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_2UM'  } )
 _nPos3UM  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_3UM'  } )
 aCols[N,_nPosDesc] := Posicione("SB1",1,FWxfilial("SB1")+_cCodProd,"B1_DESC")
 aCols[N,_nPosDesD] := SB1->B1_I_DESCD
 aCols[N,_nPosUM  ] := SB1->B1_UM
 aCols[N,_nPos2UM ] := SB1->B1_SEGUM
 aCols[N,_nPos3UM ] := SB1->B1_I_3UM
Return .T.


/*
===============================================================================================================================
Programa--------: AOMS063X
Autor-----------: Alex Wallauer
Data da Criacao-: 29/05/2025
Descrição-------: Gera Excel ou xml dos dados da tela
Parametros------: _lXML: .T. gera XML senão Excel
Retorno---------: .T.
===============================================================================================================================
*/
Static Function AOMS063X(_lXML As Logical) As Logical
 Local _lComCab := .T. As Logical
 Local _cTitAux := "Metas de "+SubStr(cAnoMes,5,2)+"/"+SubStr(cAnoMes,1,4)+" do "+Lower(cTipoor)+" "+cCoord+" - "+cNmCoor As Char
 Local _aCabExc := {} As Array
 Local _aLinhas := {} As Array
 Local _aLinAux := AClone(aCols) As Array
 Local _nRep    := 0 As Numeric

 //    Array com o cabeçalho das colunas do relatório.
 //    Alinhamento( 1-Left,2-Center,3-Right )
 //    Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
 //                        Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
 AAdd(_aCabExc,{"Cod. Produto"                ,2           ,1         ,.F.})
 AAdd(_aCabExc,{"Descricao Produto"           ,1           ,1         ,.F.})
 AAdd(_aCabExc,{"Descricao Completa"          ,1           ,1         ,.F.})
 AAdd(_aCabExc,{"Quantidade 1a UM"            ,3           ,2         ,.F.})
 AAdd(_aCabExc,{"1a UM"                       ,2           ,1         ,.F.})
 AAdd(_aCabExc,{"Quantidade 2a UM"            ,3           ,2         ,.F.})
 AAdd(_aCabExc,{"2a UM"                       ,2           ,1         ,.F.})
 AAdd(_aCabExc,{"Quantidade 3a UM"            ,3           ,2         ,.F.})
 AAdd(_aCabExc,{"3a UM"                       ,2           ,1         ,.F.})
 AAdd(_aCabExc,{"Valor"                       ,3           ,3         ,.F.})

 _aLinhas:= {}
 For _nRep := 1 to Len(_aLinAux)
     aDel(_aLinAux[_nRep], Len(_aLinAux[_nRep]) )//Remove a ultima coluna do Del
     aSize(_aLinAux[_nRep],Len(_aLinAux[_nRep])-1)
     AAdd(_aLinhas, _aLinAux[_nRep] )
 Next _nRep

 If _lXML
    //ITGEREXCEL(_cNomeArq,_cDiretorio,_cTitulo,_cNomePlan,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte,_lEnviaEmail,_lXLSX,_lComCab
    //Exportação para Excel (.XML)
    FWMsgRun( ,{|_oProc| U_ITGEREXCEL(,,_cTitAux,,_aCabExc,_aLinhas,,,,,,,,.F.,_oProc,_lComCab),;
                         U_ITMsg("Geração Concluida!  ["+DToC(DATE())+"] ["+TIME()+"]") },;
                         "H.I. : "+TIME()+" - Aguarde...","Gerando Excel (.XML)..."  )
 Else
    //Exportação para Excel (.XLSX)
    FWMsgRun( ,{|_oProc| U_ITGEREXCEL(,,_cTitAux,,_aCabExc,_aLinhas,,,,,,,,.T.,_oProc,_lComCab),;
                         U_ITMsg("Geração Concluida!  ["+DToC(DATE())+"] ["+TIME()+"]") },;
                         "H.I. : "+TIME()+" - Aguarde...","Gerando Excel (.XLSX)..." )
 EndIf

Return .T.


/*
===============================================================================================================================
Programa--------: AOMS063MD
Autor-----------: Alex Wallauer
Data da Criacao-: 04/06/2025
Descrição-------: Manutenção do % diario
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS063MD()

 Local _cTitulo  := "Manutenção do % de meta diário" As Char
 Local nGDAction := 0 As Numeric
 Local _aSize    := {} As Array
 Local _aInfo    := {} As Array
 Local aObjects  := {} As Array
 Local aPosObj   := {} As Array
 Local _aAnos    := {} As Array
 Local _aAnosGrv := {} As Array
 Local _dDataAtual:= dDataBase As Date
 Local _cAnoAtual:= LEFT(DToS(_dDataAtual),4) As Char
 Local _cAno     := LEFT(DToS(_dDataAtual),4) As Char
 Local _cAnoAux  := "" As Char
 Local _nAno     := 00 As Numeric
 Local _nOpca    := 00 As Numeric
 Local nLinha    := 10 As Numeric
 Local oOrdem          As Object
 Local oBotao1         As Object
 Local oBotao2         As Object
 Local oBotao3         As Object
 Local oBotao4         As Object
 Local oBotao5         As Object
 Local oDlg2           As Object
 Local oDlgAno         As Object
 Private oMsMGet       As Object
 Private aHeader := {} As Array
 Private aCols   := {} As Array

 For _nAno := (Year(_dDataAtual)-5) to (Year(_dDataAtual)+10)
     If ZPA->(MSSeek(FWxfilial("ZPA")+StrZero(_nAno,4)))
        AAdd(_aAnos,StrZero(_nAno,4)+" (I)")
        If _cAno = StrZero(_nAno,4)
           _cAno:= StrZero(_nAno,4)+" (I)"
        EndIf
     Else
        AAdd(_aAnos,StrZero(_nAno,4))
     EndIf
 Next _nAno

 For _nAno := (Year(_dDataAtual)-15) to (Year(_dDataAtual)+15)
     If ZPA->(MSSeek(FWxfilial("ZPA")+StrZero(_nAno,4)))
        AAdd(_aAnosGrv,StrZero(_nAno,4))
     EndIf
 Next _nAno

 While .T.
    nGDAction:=-1
    DEFINE MSDIALOG oDlgAno FROM 0,0 TO 200,300 PIXEL TITLE 'Escolha o ano e a manutenção'

         nLinha:= 25
       @ nLinha,10 ComboBox _cAno ITEMS _aAnos Size 35,10 Object oOrdem
       @ nLinha,55 Button "Visualizar"         Size 55,12 PIXEL OF oDlgAno action (nGDAction:=0,oDlgAno:end())
         nLinha+= 15
       @ nLinha,55 Button "Incluir / Alterar"  Size 55,12 PIXEL OF oDlgAno action (nGDAction:=GD_UPDATE,oDlgAno:end())
         nLinha+= 15
       @ nLinha,55 Button "Excluir"            Size 55,12 PIXEL OF oDlgAno action (nGDAction:=GD_DELETE,oDlgAno:end())
         nLinha+= 15
       @ nLinha,55 Button "Voltar"             Size 55,12 PIXEL OF oDlgAno action (nGDAction:=-1,oDlgAno:end())
         nLinha+= 20
       @ 10,05 To nLinha,130 Title " Escolha o ano e a manutenção: "

    ACTIVATE MSDIALOG oDlgAno CENTERED

    If nGDAction = -1
       Return
    EndIf
    _cSalvaAno:=_cAno //Variavel auxiliar para o ano
    _cAno:=LEFT(_cAno,4)

    If nGDAction = 0 .And. !ZPA->(MSSeek(FWxfilial("ZPA")+_cAno)) //CRIA DE NÃO TIVER AINDA

       If !U_ITMsg("Ano não cadastrodo.",'Atenção!',"Deseja cadastrar?",2,2,3,,"CONFIRMA","VOLTAR")
          _cAno:=_cSalvaAno
          Loop
       EndIf
       nGDAction:= GD_UPDATE

    ElseIf nGDAction = GD_DELETE

       If ZPA->(MSSeek(FWxfilial("ZPA")+_cAno))
          If _cAnoAtual <= _cAno .And. !AllTrim(GETENVSERVER()) == "HOMOLOGACAO_ALEXANDRO"
             U_ITMsg("Não é possível excluir o ano atual ou inferior: "+_cAno,"Atenção",,3)
             _cAno:=_cSalvaAno
             Loop
          EndIf
       Else
          U_ITMsg("Registros não encontrado para o ano "+_cAno,"Atenção",,3)
          _cAno:=_cSalvaAno
          Loop
       EndIf

       If !U_ITMsg("Confirma a exclusao do Ano de "+_cAno+' ?','Atenção!',,2,2,3,,"CONFIRMA","VOLTAR")
          _cAno:=_cSalvaAno
          Loop
       EndIf

       FWMsgRun( ,{|oProc| AOMS063Ger("EXCLUIR_META_ANUAL",_cAno) }, 'Aguarde!' , 'Excluindo As datas/metas...'  )
       Return
    EndIf

    Exit

 EndDo

 FWMsgRun( ,{|oProc| AOMS063Ger("LER_META_ANUAL",_cAno) }, 'Aguarde!' , 'Carregando As datas/metas...'  )

 _bTotais:={|| FWMsgRun( ,{|oProc| AOMS063Ger("SOMAR_PERCENTUAL",,,oMsMGet) }, 'Aguarde!' , 'Somando % por mes...'  )  }

 // pega tamanhos das telas
 _aSize := MsAdvSize()
 _aInfo := { _aSize[1] , _aSize[2] , _aSize[3] , _aSize[4] , 1 , 1 }

 aObjects := {}
 AAdd( aObjects, { 100 , 100 , .T. , .T. } )
 AAdd( aObjects, { 100 , 100 , .T. , .T. } )
 AAdd( aObjects, { 100 , 100 , .T. , .T. } )
 aPosObj := MsObjSize( _aInfo , aObjects )
 _cAnoAux:= _cAno //Variavel auxiliar para o ano
 While .T.

    _nOpca:= 0
    DEFINE MSDIALOG oDlg2 TITLE _cTitulo+" do Ano "+_cAno OF oMainWnd PIXEL FROM _aSize[7],0 TO _aSize[6],_aSize[5]

      If nGDAction = GD_UPDATE
         @ 005,050 Button "GRAVAR" Size 55,13 Action ( _nOpca := 3 , oDlg2:End() ) Object oBotao1
         @ 005,110 Button "TOTAIS" Size 55,13 Action ( Eval(_bTotais)            ) Object oBotao2
         @ 005,170 Button "SAIR"   Size 55,13 Action ( _nOpca := 0 , oDlg2:End() ) Object oBotao3
      Else
         _nAlt :=30
         _nLarg:=99
         _nCol :=50
         @ 005,_nCol BTNBMP oBotao1 RESOURCE "VOLTAR2_OCEAN"      SIZE _nLarg,_nAlt PIXEL OF oDlg2 ACTION ( _nOpca := -2 , oDlg2:End() )
         _nCol+=100
         @ 005,_nCol BTNBMP oBotao2 RESOURCE "VOLTAR_OCEAN"       SIZE _nLarg,_nAlt PIXEL OF oDlg2 ACTION ( _nOpca := -1 , oDlg2:End() )
         _nCol+=100
         @ 005,_nCol BTNBMP oBotao3 RESOURCE "AVANCAR_OCEAN.BMP"  SIZE _nLarg,_nAlt PIXEL OF oDlg2 ACTION ( _nOpca :=  1 , oDlg2:End() )
         _nCol+=100
         @ 005,_nCol BTNBMP oBotao4 RESOURCE "AVANCAR2_OCEAN.BMP" SIZE _nLarg,_nAlt PIXEL OF oDlg2 ACTION ( _nOpca :=  2 , oDlg2:End() )
         _nCol+=100
         @ 005,_nCol BTNBMP oBotao5 RESOURCE "FINAL_OCEAN.BMP"    SIZE 030,030      PIXEL OF oDlg2 ACTION ( _nOpca :=  0 , oDlg2:End() )
      EndIf

      ///***********************  MSNEWGETDADOS() *************************
                              //[ nTop]          , [ nLeft]   , [ nBottom] , [ nRight ] , [ nStyle],cLinhaOk,cTudoOk,cIniCpos, [ aAlter], [ nFreeze], [ nMax], [ cFieldOk], [ cSuperDel], [ cDelOk], [ oWnd], [ aPartHeader], [ aParCols], [ uChange], [ cTela], [ aColsSize]
      oMsMGet := MsNewGetDados():New(25,aPosObj[3,2],aPosObj[3,3],aPosObj[3,4],nGDAction ,        ,       ,        ,          ,           ,        ,            ,             ,          ,oDlg2   ,aHeader        , aCols     ,)
      oDlg2:lMaximized:=.T.

    ACTIVATE MSDIALOG oDlg2

    If _nOpca = 0 //Sair

       Exit

    ElseIf _nOpca = 3 //GRAVAR

       _cMeses:= ""
       FWMsgRun( ,{|oProc| _cMeses:=AOMS063Ger("SOMAR_PERCENTUAL",,,oMsMGet) }, 'Aguarde!' , 'Somando % por mes...'  )
       If !Empty(_cMeses)
          U_ITMsg("O(s) mes(es) de "+_cMeses+" não esta com 100 % na somatoria.","Atenção","Acerte e grave novamente.",3)
          Loop
       EndIf
       FWMsgRun( ,{|oProc| AOMS063Ger("GRAVAR_META_ANUAL",_cAno) }, 'Aguarde!' , 'Gravando As datas/metas...'  )
       U_ITMsg("Gravacao concluida com sucesso","Atenção",,2)
       Exit

    ElseIf _nOpca = -2 //PRIMEIRO

       nPos:=1

    ElseIf _nOpca = -1//VOLTA UM

       nPos:=AScan(_aAnosGrv,_cAno)
       If nPos > 1
          nPos--
       Else
          nPos:=1
       EndIf

    ElseIf _nOpca = 1//AVANCAO 1

       nPos:=AScan(_aAnosGrv,_cAno)
       If nPos < (Len(_aAnosGrv)-1)
          nPos++
       Else
          nPos:=Len(_aAnosGrv)
       EndIf

    ElseIf _nOpca = 2//ULTIMO

       nPos:=Len(_aAnosGrv)

    EndIf

    _cAno:=_aAnosGrv[nPos]
    _cAnoAux:=LEFT(_cAno,4) //Pega só o ano
    If ZPA->(MSSeek(FWxfilial("ZPA")+_cAnoAux))
       FWMsgRun( ,{|oProc| AOMS063Ger("LER_META_ANUAL",_cAnoAux) }, 'Aguarde!' , 'Carregando As datas/metas...'  )
       _cAno:=_cAnoAux
    EndIf

 EndDo

Return

/*
===============================================================================================================================
Programa--------: AOMS063Ger
Autor-----------: Alex Wallauer
Data da Criacao-: 04/06/2025
Descrição-------: Leitura e geracao da Manutenção do % diario
Parametros------: _cAcao As char , _cAnoMes As char, _cCoord As char , oMsMGet As Object
Retorno---------: _cMeses //Retorna os meses que não tem 100% de somatoria na _cAcao = "SOMAR_PERCENTUAL"
===============================================================================================================================
*/
Static Function AOMS063Ger(_cAcao As char,_cAnoMes As char ,_cCoord As char , oMsMGet As Object) As Char
 Local M         := 000 As Numeric
 Local A         := 000 As Numeric
 Local N         := 000 As Numeric
 Local nCol      := 001 As Numeric
 Local nPosProd  := 000 As Numeric
 Local _nQtde1um := 000 As Numeric
 Local _nQtde2um := 000 As Numeric
 Local _nQtde3um := 000 As Numeric
 Local _nValorMe := 000 As Numeric
 Local cProd     := " " As Char
 Local _cChave   := " " As Char
 Local _cOperacao:= " " As Char
 Local _cData    := " " As Char
 Local _lAchou   := .F. As Logical
 Local xObj      := Nil As Object
 Local _aAreaZZS := ZZS->(FwGetArea()) //SALVA A AREA DE ZZS INDICE E RECNO

 //************************************//
 If _cAcao = "GERAR_VALORES_POR_DATA"
 //************************************//
    ZZA->(DBSetOrder(1))//ZPA_FILIAL+ZPA_SDATA
    If ZPA->(MSSeek(FWxfilial("ZPA")+_cAnoMes))

       _cChave   := ZZS->ZZS_FILIAL+ZZS->ZZS_ANOMES+ZZS->ZZS_COOR+ZZS->ZZS_COD
       _nQtde1um := ZZS->ZZS_QTD
       _nQtde2um := ZZS->ZZS_QTD2UM
       _nQtde3um := ZZS->ZZS_QTD3UM
       _nValorMe := ZZS->ZZS_VALOR
       _cOperacao:= AllTrim(ZGW->ZGW_OPER)+"_DT"

       SB1->(DBSetOrder(1))
       SB1->(MSSeek(FWxfilial("SB1")+ZZS->ZZS_COD))
       SA3->(DBSetOrder(1))
       SA3->(MSSeek(FWxfilial("SA3")+ZZS->ZZS_COOR))
       ZZS->(DBSetOrder(7))//ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD+ZZS_DATA

       While ZPA->(!Eof()) .And. FWxfilial("ZPA")+_cAnoMes == ZPA->(ZPA_FILIAL+LEFT(ZPA_SDATA,6))//SÓ ANO + MES
                             //esse campo de ZPA_SDATA é o ano+mes+dia caracter,ex:20250101
          _lAchou:=ZZS->(MSSeek(_cChave+ZPA->ZPA_SDATA)) //ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD+ZZS_DATA

          ZZS->(RecLock("ZZS",!_lAchou))
          If !_lAchou//Se não achou, inclui
             ZZS->ZZS_ANOMES := _cAnoMes
             ZZS->ZZS_COD    := SB1->B1_COD
             ZZS->ZZS_DESCR  := SB1->B1_DESC
             ZZS->ZZS_DESCD  := SB1->B1_I_DESCD
             ZZS->ZZS_UM     := SB1->B1_UM
             ZZS->ZZS_2UM    := SB1->B1_SEGUM
             ZZS->ZZS_3UM    := SB1->B1_I_3UM
             ZZS->ZZS_COOR   := SA3->A3_COD
             ZZS->ZZS_NMCOOR := SA3->A3_NOME
             ZZS->ZZS_TIPOV  := SA3->A3_I_TIPV
             ZZS->ZZS_DATA   := SToD(ZPA->ZPA_SDATA)
          EndIf
          ZZS->ZZS_QTD    := ((_nQtde1um*ZPA->ZPA_PERCE)/100)
          ZZS->ZZS_QTD2UM := ((_nQtde2um*ZPA->ZPA_PERCE)/100)
          ZZS->ZZS_QTD3UM := ((_nQtde3um*ZPA->ZPA_PERCE)/100)
          ZZS->ZZS_VALOR  := ((_nValorMe*ZPA->ZPA_PERCE)/100)
          ZZS->(MSUnLock())

          ZGW->(RecLock("ZGW",.T.))//_cOperacao+"_DT"
          ZGW->ZGW_FILIAL := FWxfilial("ZGW")
          ZGW->ZGW_COD    := ZZS->ZZS_COD
          ZGW->ZGW_DESCR  := ZZS->ZZS_DESCR
          ZGW->ZGW_DESCD  := ZZS->ZZS_DESCD
          ZGW->ZGW_UM     := ZZS->ZZS_UM
          ZGW->ZGW_QTD    := ZZS->ZZS_QTD
          ZGW->ZGW_QTD2UM := ZZS->ZZS_QTD2UM
          ZGW->ZGW_2UM    := ZZS->ZZS_2UM
          ZGW->ZGW_QTD3UM := ZZS->ZZS_QTD3UM//Novo
          ZGW->ZGW_3UM    := ZZS->ZZS_3UM   //Novo
          ZGW->ZGW_VALOR  := ZZS->ZZS_VALOR //Novo
          ZGW->ZGW_TIPOV  := ZZS->ZZS_TIPOV //Novo
          ZGW->ZGW_DATAM  := ZZS->ZZS_DATA  //Novo
          ZGW->ZGW_COOR   := ZZS->ZZS_COOR
          ZGW->ZGW_NMCOOR := ZZS->ZZS_NMCOOR
          ZGW->ZGW_ANOMES := ZZS->ZZS_ANOMES
          ZGW->ZGW_OPER   := _cOperacao
          ZGW->ZGW_USER   := _cUserName
          ZGW->ZGW_DATA   := Date()
          ZGW->ZGW_HORA   := Time()
          ZGW->(MSUnLock())

          ZPA->(DBSkip())
       EndDo
       FwRestArea(_aAreaZZS)//VOLTA A AREA DE ZZS INDICE E RECNO
    EndIf

 //************************************************************************************//
 ElseIf _cAcao = "EXCLUIR_VALORES_POR_DATA"
 //************************************************************************************//
    ZZS->(DBSetOrder(7))//ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD+ZZS_DATA
    _cChave   := ZZS->ZZS_FILIAL+ZZS->ZZS_ANOMES+ZZS->ZZS_COOR+ZZS->ZZS_COD
    _lAchou   := ZZS->(MSSeek(_cChave)) //ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD+ZZS_DATA
    _cOperacao:= AllTrim(ZGW->ZGW_OPER)+"_DT"

    While ZZS->(!Eof()) .And. _cChave == ZZS->(ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD)
       If Empty(ZZS->ZZS_DATA)
          ZZS->(DBSkip())
          Loop
       EndIf
       ZGW->(RecLock("ZGW",.T.))//_cOperacao+"_DT"
       ZGW->ZGW_FILIAL := FWxfilial("ZGW")
       ZGW->ZGW_COD    := ZZS->ZZS_COD
       ZGW->ZGW_DESCR  := ZZS->ZZS_DESCR
       ZGW->ZGW_DESCD  := ZZS->ZZS_DESCD
       ZGW->ZGW_UM     := ZZS->ZZS_UM
       ZGW->ZGW_QTD    := ZZS->ZZS_QTD
       ZGW->ZGW_QTD2UM := ZZS->ZZS_QTD2UM
       ZGW->ZGW_2UM    := ZZS->ZZS_2UM
       ZGW->ZGW_QTD3UM := ZZS->ZZS_QTD3UM//Novo
       ZGW->ZGW_3UM    := ZZS->ZZS_3UM   //Novo
       ZGW->ZGW_VALOR  := ZZS->ZZS_VALOR //Novo
       ZGW->ZGW_TIPOV  := ZZS->ZZS_TIPOV //Novo
       ZGW->ZGW_DATAM  := ZZS->ZZS_DATA  //Novo
       ZGW->ZGW_COOR   := ZZS->ZZS_COOR
       ZGW->ZGW_NMCOOR := ZZS->ZZS_NMCOOR
       ZGW->ZGW_ANOMES := ZZS->ZZS_ANOMES
       ZGW->ZGW_OPER   := _cOperacao
       ZGW->ZGW_USER   := _cUserName
       ZGW->ZGW_DATA   := Date()
       ZGW->ZGW_HORA   := Time()
       ZGW->(MSUnLock())

       ZZS->(RecLock("ZZS",.F.))
       ZZS->(DbDelete())
       ZZS->(MSUnLock())
       ZZS->(DBSkip())
    EndDo
    FwRestArea(_aAreaZZS)//VOLTA A AREA DE ZZS INDICE E RECNO

 //************************************************************************************//
 ElseIf _cAcao = "GRAVAR_META_ANUAL"//não usa _cAnoMes
 //************************************************************************************//
    For A := 1 TO 12
       For M := 1 TO Len(aCols)
           If Empty(aCols[M,nCol])//Não tem como o usuario por data em branco , server de controle de meses com mesmo de 31 dias
              Loop
           EndIf
           _cSData:=DToS(aCols[M,nCol])
           _nPerc :=aCols[M,(nCol+1)]
           If ZPA->(MSSeek(FWxfilial("ZPA")+_cSData))
              ZPA->(RecLock("ZPA",.F.))
              ZPA->ZPA_PERCE:=_nPerc
              ZPA->(MSUnLock())
           ElseIf _nPerc > 0//Só inclui um reg se tiver percentual e data preenchidos
              ZPA->(RecLock("ZPA",.T.))
              ZPA->ZPA_SDATA:=_cSData
              ZPA->ZPA_PERCE:=_nPerc
              ZPA->(MSUnLock())
           EndIf
        Next M
        nCol:=nCol+2
    Next A

 //************************************************************************************//
 ElseIf _cAcao = "EXCLUIR_META_ANUAL"//_cAnoMes: Ler Ano 4 digitos
 //************************************************************************************//
    If ZPA->(MSSeek(FWxfilial("ZPA")+_cAnoMes))
       While ZPA->(!Eof()) .And. FWxfilial("ZPA")+_cAnoMes == ZPA->(ZPA_FILIAL+LEFT(ZPA_SDATA,4))
          ZPA->(RecLock("ZPA",.F.))
          ZPA->(DbDelete())
          ZPA->(DBSkip())
       EndDo
       U_ITMsg("Registros excluiodos do ano "+_cAnoMes+" com SUCESSO.","Atenção",,2)
    Else
       U_ITMsg("Registros não encontrado para o ano "+_cAnoMes,"Atenção",,3)
    EndIf

 //************************************************************************************//
 ElseIf _cAcao = "LER_META_ANUAL"//_cAnoMes: Ler Ano 4 digitos
 //************************************************************************************//

    aHeader:={}
    /////aHeader,{X3_TITULO  ,   CAMPO   ,PICT,Tamanho,D,Validacao        ,USADO,X3_TIPO,ARQUIVO,X3_CONTEXT,X3_CBOX,X3_RELACAO,X3_WHEN,X3_VISUAL,X3_VLDUSER,X3_PICTVAR,X3_OBRIGAT
    AAdd(aHeader,{"Janeiro"  ,"TRB_JAN_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_JAN_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Fevereiro","TRB_FEV_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_FEV_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Março"    ,"TRB_MAR_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_MAR_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Abril"    ,"TRB_ABR_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_ABR_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Maio"     ,"TRB_MAI_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_MAI_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Junho"    ,"TRB_JUN_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_JUN_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Julho"    ,"TRB_JUL_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_JUL_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Agosto"   ,"TRB_AGO_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_AGO_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Setembro" ,"TRB_SET_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_SET_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Outubro"  ,"TRB_OUT_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_OUT_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Novembro" ,"TRB_NOV_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_NOV_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})
    AAdd(aHeader,{"Dezembro" ,"TRB_DEZ_D","@D"     ,08,0,"               ","","D","","","","",".F."})
    AAdd(aHeader,{"%"        ,"TRB_DEZ_P","@E 99.9",04,1,'U_AOMS063V("%")',"","N","","","","",".T."})

    If !ZPA->(MSSeek(FWxfilial("ZPA")+_cAnoMes)) //CRIA SE NÃO TIVER AINDA - CARGA INICIAL DO ANO SELECIONADO
       For A := 1 TO 31
           _aLinhas:={}
           For M := 1 TO 12
               _cData:=StrZero(A,2)+"/"+StrZero(M,2)+"/"+_cAnoMes
               If !Empty(CTOD(_cData))
                  AAdd(_aLinhas,CTOD(_cData))
                  If A >= 1 .And. A <= 15// Todos os Meses
                     AAdd(_aLinhas,4)
                  ElseIf A >= 16 .And. StrZero(M,2) $ "01,03,05,07,08,10,12" // meses com 31 dias
                     AAdd(_aLinhas,2.5)
                  ElseIf A >= 16 .And. A <= 22 .And. StrZero(M,2) $ "04,06,09,11" // meses com 30 dias
                     AAdd(_aLinhas,2.9)
                  ElseIf A >= 23 .And. A <= 29 .And. StrZero(M,2) $ "04,06,09,11" // meses com 30 dias
                     AAdd(_aLinhas,2.5)
                  ElseIf A = 30 .And. StrZero(M,2) $ "04,06,09,11" // meses com 30 dias
                     AAdd(_aLinhas,2.2)
                  ElseIf M = 2 // Fevereiro e Bisexto
                     If A >= 16 .And. A <= 21
                        AAdd(_aLinhas,3.3)
                     ElseIf A >= 22 .And. A <= 27
                        AAdd(_aLinhas,2.9)
                     ElseIf A = 28
                        AAdd(_aLinhas,2.8)
                     ElseIf A = 29
                        AAdd(_aLinhas,0)
                     EndIf
                  EndIf
               Else
                  AAdd(_aLinhas,CTOD(""))
                  AAdd(_aLinhas,0)
               EndIf
           Next M
           AAdd(_aLinhas,.F.)
           AAdd(aCols,_aLinhas)
       Next A
    Else//LER SE EXISTE *************************************************************************************//
       _aColAux:={}
       While ZPA->(!Eof()) .And. FWxfilial("ZPA")+_cAnoMes == ZPA->(ZPA_FILIAL+LEFT(ZPA_SDATA,4))
          AAdd(_aColAux,{ ZPA->ZPA_SDATA , ZPA->ZPA_PERCE })
          ZPA->(DBSkip())
       EndDo
       aCols:={}
       For A := 1 TO 31
           _aLinhas:={}
           For M := 1 TO 12
               _cData:=_cAnoMes+StrZero(M,2)+StrZero(A,2)
               _nPos:=AScan(_aColAux,{ |x| x[1] == _cData })
               If _nPos > 0
                  AAdd(_aLinhas,SToD(_aColAux[_nPos,1]))
                  AAdd(_aLinhas,_aColAux[_nPos,2])
               Else
                  AAdd(_aLinhas,CTOD(""))
                  AAdd(_aLinhas,0)
               EndIf
           Next
           AAdd(_aLinhas,.F.)
           AAdd(aCols,_aLinhas)
       Next

    EndIf
 //************************************************************************************//
 ElseIf _cAcao = "SOMAR_PERCENTUAL"//não usa _cAnoMes
 //************************************************************************************//
    //Calcula o percentual de cada mes
    aCols:=oMsMGet:aCols
    _aTotais:={}
    _cMeses:=""
    nCol:=1
    For A := 1 TO 12
        For M := 1 TO Len(aCols)
           If Empty(aCols[M,nCol])//Não tem como o usuario por data em branco , server de controle de meses com mesmo de 31 dias
              Loop
           EndIf
           _cSData:=MesExtenso( Month( aCols[M,nCol]) )
           _nPerc :=aCols[M,(nCol+1)]
           If (nPos:=AScan(_aTotais,{ |D| D[2] = _cSData })) > 0
              _aTotais[nPos,3] += _nPerc
              _aTotais[nPos,1] := (_aTotais[nPos,3] = 100)
           Else
               AAdd(_aTotais,{ .F. ,_cSData , _nPerc })
           EndIf
        Next M
        nCol:=nCol+2
    Next A

    _aColXML:=aClone(_aTotais)

    For A := 1 TO Len(_aTotais)
       If !_aTotais[A,1] //Se o mes não tem 100% de somatoria
          _cMeses+="["+_aTotais[A,2]+"] "
       EndIf
       _aTotais[A,3]:= Trans(_aTotais[A,3],"@E 999.99")+" %"
    Next A

    _aCabTot:={}
    AAdd(_aCabTot,"   "    )
    AAdd(_aCabTot,"Mes"    )
    AAdd(_aCabTot,"Total %")
    _cMsg:=NIL
    If !Empty(_cMeses)
       _cMsg:="O(s) mes(es) de "+_cMeses+"não esta com 100 % na somatoria."
    EndIf
    _cTitulo:="Conferencia do Total (100%) por mes das Metas Anuais"
    //ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk,_aSX1,_lComCab)
    U_ITListBox( _cTitulo , _aCabTot, _aTotais  , .F.    , 4      ,_cMsg     ,          ,         ,         ,     ,        ,          ,       ,         , _aColXML ,)

    Return _cMeses //Retorna os meses que não tem 100% de somatoria  //*********************  RETORNO  ****************************//

 //************************************************************************************//
 ElseIf _cAcao = "LISTA_META_POR_DIA"//_cAnoMes: Ler AnoMes 6 digitos
 //************************************************************************************//
    nPosProd  := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_COD'   })
    nPosQTD   := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD'   })
    nPosUM    := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_UM'    })
    nPosQTD2U := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD2UM'})
    nPos2UM   := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_2UM'   })
    nPosQTD3U := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_QTD3UM'})
    nPos3UM   := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_3UM'   })
    nPosVALOR := AScan(aHeader,{ |x| AllTrim(x[2]) == 'ZZS_VALOR' })
    xObj      := CallMod2Obj()
    N         := xObj:oBrowse:nat
    cProd     := aCols[N,nPosProd]
    _cChave   := FWxfilial("ZZS")+_cAnoMes+_cCoord+cProd

    ZZS->(DBSetOrder(7))  // ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD+ZZS_DATA
    ZZS->(MSSeek(_cChave))// ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD
    ZZA->(DBSetOrder(1))  // ZPA_FILIAL+ZPA_SDATA
    lAchou:=.F.
    _aProdDia:={}
    _aTotais:={0,0,0,0,0,0,0} //Acumula os totais de cada coluna
    While ZZS->(!Eof()) .And. _cChave == ZZS->(ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD)
       If Empty(ZZS->ZZS_DATA)
          ZZS->(DBSkip())
          Loop
       EndIf
       ZPA->(MSSeek(FWxfilial("ZPA")+DToS(ZZS->ZZS_DATA)))
       AAdd(_aProdDia,{DToC(ZZS->ZZS_DATA),;//01
                       ZPA->ZPA_PERCE     ,;//02
                       ZZS->ZZS_QTD       ,;//03
                       ZZS->ZZS_UM        ,;//04
                       ZZS->ZZS_QTD2UM    ,;//05
                       ZZS->ZZS_2UM       ,;//06
                       ZZS->ZZS_QTD3UM    ,;//07
                       ZZS->ZZS_3UM       ,;//08
                       ZZS->ZZS_VALOR     })//09

       _aTotais[1] +=  ZZS->ZZS_QTD
       _aTotais[2] +=  ZZS->ZZS_QTD2UM
       _aTotais[3] +=  ZZS->ZZS_QTD3UM
       _aTotais[4] +=  ZZS->ZZS_VALOR
       _aTotais[5] +=  ZPA->ZPA_PERCE
       lAchou:=.T.
       ZZS->(DBSkip())
    EndDo

    If !lAchou
       U_ITMsg("Não existem datas para o produto "+AllTrim(cProd)+" no mes "+SubStr(_cAnoMes,5,2)+"/"+SubStr(_cAnoMes,1,4),"Atenção","A meta diaria do produto é gravada atuomaticamente na gravaçõo das metas mensais.",3)
       Return "" //*********************  RETORNO  ****************************//
    EndIf

    ZZS->(MSSeek(_cChave+" ")) //ZZS_FILIAL+ZZS_ANOMES+ZZS_COOR+ZZS_COD

    AAdd(_aProdDia,{"SOMAS:"    ,;//01
                    _aTotais[5] ,;//02
                    _aTotais[1] ,;//03
                    ZZS->ZZS_UM ,;//04
                    _aTotais[2] ,;//05
                    ZZS->ZZS_2UM,;//06
                    _aTotais[3] ,;//07
                    ZZS->ZZS_3UM,;//08
                    _aTotais[4] })//09

    AAdd(_aProdDia,{"TOTAIS:"         ,;//01
                    100               ,;//02
                    aCols[N,nPosQTD  ],;//03
                    aCols[N,nPosUM   ],;//04
                    aCols[N,nPosQTD2U],;//05
                    aCols[N,nPos2UM  ],;//06
                    aCols[N,nPosQTD3U],;//07
                    aCols[N,nPos3UM  ],;//08
                    aCols[N,nPosVALOR]})//09

    AAdd(_aProdDia,{"Diferença:"                      ,;//01
                    (100               -_aTotais[5] ) ,;//02
                    (aCols[N,nPosQTD  ]-_aTotais[1] ) ,;//03
                    (aCols[N,nPosUM   ]             ) ,;//04
                    (aCols[N,nPosQTD2U]-_aTotais[2] ) ,;//05
                    (aCols[N,nPos2UM  ]             ) ,;//06
                    (aCols[N,nPosQTD3U]-_aTotais[3] ) ,;//07
                    (aCols[N,nPos3UM  ]             ) ,;//08
                    (aCols[N,nPosVALOR]-_aTotais[4] ) })//09

     _aColXML:=AClone(_aProdDia)

    For A := 1 TO Len(_aProdDia)
       _aProdDia[A,2]:= AllTrim(Trans(_aProdDia[A,2],"@E 999,999,999.99"))
       _aProdDia[A,3]:= AllTrim(Trans(_aProdDia[A,3],"@E 999,999,999.99"))
       _aProdDia[A,5]:= AllTrim(Trans(_aProdDia[A,5],"@E 999,999,999.99"))
       _aProdDia[A,7]:= AllTrim(Trans(_aProdDia[A,7],"@E 999,999,999.99"))
       _aProdDia[A,9]:= AllTrim(Trans(_aProdDia[A,9],"@E 999,999,999.99"))
    Next A

    _aCabDT:={}
    AAdd(_aCabDT,"Data"    )
    AAdd(_aCabDT,"%"       )
    AAdd(_aCabDT,"Qtde 1Um")
    AAdd(_aCabDT,"1a Um"   )
    AAdd(_aCabDT,"Qtde 2Um")
    AAdd(_aCabDT,"2a Um"   )
    AAdd(_aCabDT,"Qtde 3Um")
    AAdd(_aCabDT,"3a Um"   )
    AAdd(_aCabDT,"Valor"   )

    _cTitulo:="Valores por Dia do Produto "+cProd+" no mes "+SubStr(_cAnoMes,5,2)+"/"+SubStr(_cAnoMes,1,4)
    //ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk,_aSX1,_lComCab)
    U_ITListBox( _cTitulo , _aCabDT , _aProdDia , .F.    , 1      ,          ,          ,         ,         ,     ,        ,          ,       ,         , _aColXML ,)

    FwRestArea(_aAreaZZS)//VOLTA A AREA DE ZZS INDICE E RECNO

 EndIf

Return ""

/*
===============================================================================================================================
Programa--------: AOMS063Conv
Autor-----------: Alex Wallauer
Data da Criacao-: 04/06/2025
Descrição-------: Conversão do volume importado o do % diario
Parametros------: _nVolume,_cUnidade,_cUMDest,_nQtde1um,_nQtde2um,_nQtde3um
Retorno---------: _nVolume
===============================================================================================================================
*/
Static Function AOMS063Conv(_nVolume As Numeric,_cUnidade As Char,_cUMDest As Char,_nQtde1um As Numeric,_nQtde2um As Numeric,_nQtde3um As Numeric)
 Local _nFator := 0 As Numeric
 
  //**************************************************
 If _cUnidade == SB1->B1_UM        // CONVERSAO DA PRIMEIRA UM PARA 2UM e 3UM...

     If SB1->B1_CONV == 0
         If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
             _nFator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
         EndIf
     Else
         _nFator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
     EndIf
     _nQtde1um:=_nVolume
     _nQtde2um:=If(_nFator>0,_nVolume*_nFator,_nVolume)
     If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_SEGUM = 'PC' .And. SB1->B1_I_3UM = 'CX'
        _nQtde3um:=( _nQtde2um / SB1->B1_I_QT3UM)// Conversão da SEGUNDA UM para a Terceira UM
     Else
        _nQtde3um:=( _nQtde1um / SB1->B1_I_QT3UM )// Conversão da PRIMEIRA UM para a Terceira UM
     EndIf

  //**************************************************
 ElseIf _cUnidade == SB1->B1_SEGUM // CONVERSAO DA SEGUNDA  UM PARA 1IM e 3UM...

     If SB1->B1_CONV == 0
         If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
             _nFator := If(SB1->B1_TIPCONV=="M", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
         EndIf
     Else
         _nFator := If(SB1->B1_TIPCONV=="M", 1/SB1->B1_CONV,SB1->B1_CONV)
     EndIf
     _nQtde1um:=If(_nFator>0,_nVolume*_nFator,_nVolume)// Conversão da Segunda UM para a Primeira UM

     _nQtde2um:=_nVolume

      If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_SEGUM = 'PC' .And. SB1->B1_I_3UM = 'CX'
         _nQtde3um:= _nQtde2um  / SB1->B1_I_QT3UM // Conversão da SEGUNDA UM para a Terceira UM
      Else
         _nQtde3um:= _nQtde1um  / SB1->B1_I_QT3UM // Conversão da PRIMEIRA UM para a Terceira UM
      EndIf

  //***************************************************
 ElseIf _cUnidade == SB1->B1_I_3UM // CONVERSAO DA TERCEIRA UM PARA 1UM e 2UM...

     _nQtde1um:= _nVolume * SB1->B1_I_QT3UM// Conversão #Normal* da Terceira UM para a Primeira UM

     _nQtde3um:= _nVolume

     If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_SEGUM = 'PC' .And. SB1->B1_I_3UM = 'CX'// Se Queijo*

        _nQtde2um:= _nQtde3um * SB1->B1_I_QT3UM// Conversão da Terceira UM para a Segunda UM

        If SB1->B1_CONV == 0
            If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                _nFator := If(SB1->B1_TIPCONV=="M", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
            EndIf
        Else
            _nFator := If(SB1->B1_TIPCONV=="M", 1/SB1->B1_CONV,SB1->B1_CONV)
        EndIf

        _nQtde1um:= _nQtde2um * _nFator // Conversão da Segunda UM para a Primeira UM

     Else//Calculo #Normal* se ser queijo
        If SB1->B1_CONV = 0
            If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                _nFator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
            EndIf
        Else
            _nFator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
        EndIf

        _nQtde2um:= _nQtde1um * _nFator// Conversão da Primeira UM para a Segunda UM

     EndIf

 EndIf
 If !Empty(_cUMDest)
    If _cUMDest == SB1->B1_UM
       _nVolume:=_nQtde1um
    ElseIf _cUMDest == SB1->B1_SEGUM
       _nVolume:=_nQtde2um
    ElseIf _cUMDest == SB1->B1_I_3UM
       _nVolume:=_nQtde3um
    EndIf
 EndIf
Return _nVolume
