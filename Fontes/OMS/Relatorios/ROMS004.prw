/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |   Data   |                              Motivo
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer | 20/02/24 | Chamado 45062. Andre. Incluir após ao final, Para informar hora inicial e final do carregamento.
 Lucas Borges  | 28/08/24 | Chamado 47940. Incluída proteção na classe evitando error.log.
 Lucas Borges  | 29/08/24 | Chamado 48351 e 48349. Modificado o posicionamento da proteção.
 Lucas Borges  | 22/04/25 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico.
==============================================================================================================================================================================================
 Analista      - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================================================
 Alex Wallauer - Alex Wallauer - 11/11/24 - 23/07/25 - 49966   - CORREÇÃO DE ERROR.LOG: array out of bounds ( 1 of 0 )  on U_ROMS004(ROMS004.PRW) 28/11/2024 07:13:37 line : 264
 Vanderlei     - Alex Wallauer - 09/04/25 - 23/07/25 - 49894   - Acerto dos rateios de peso bruto por itens de nota fiscal. Ler campo C6_I_PTBRU para imprimir o peso bruto correto.
 Jerry         - Julio Paz     - 21/08/25 - 27/08/25 - 50656   - Altera o Relatatório de Impressão da Ordem de Carga para Exibir a Mensagem Carga com Multa Quando Algum Pedido de Vendas da Carga for do Tipo Agendado com Multa .
 Jerry         - Alex Wallauer - 25/08/25 - 02/10/25 - 50996   - Nas Ordens MV_PARM3 = 1 e 2 , foi alterada a ordenação para Grupo PV + Desc. Grupo BI +  Desc. Grupo Família BI + Desc.
 Jerry         - Alex Wallauer - 06/10/25 - 06/10/25 - 50996   - Correção de erro.log: variable does not exist _CDESGRFA on ROMS004Cmp(ROMS004.PRW) 02/10/2025 16:45:48 line : 927.
 Jerry         - Alex Wallauer - 07/10/25 - 08/10/25 - 52374   - Correção da ordenação dos itens para o Pallets serem apresentados por ultimos.
 Jerry         - Jose Gavetti  - 17/10/25 - 17/10/25 - 52293   - Retirada tratativa do acerto de sequencia de entrega. Pacote TOTVS corrigiu a função de Geração de Documento de saída por carga
 ==============================================================================================================================================================================================
*/

#Include "FWPrintSetup.ch"
#Include "TOTVS.ch"
#Include "RPTDEF.CH"

/*
===============================================================================================================================
Programa----------: ROMS004
Autor-------------: Alexandre Villar
Data da Criacao---: 03/12/2014
Descrição---------: Relatório para impressão da Ordem de Carga
Parametros--------: _llautorel - pergunta parâmetros ou roda automático
                    _lshow - exibe relatório e mensagens na tela ou não
Retorno-----------: .T.
===============================================================================================================================
*/

User Function ROMS004(_lLAutoRel as Logical, _lshow as Logical) as Logical
 Local _nLinha:= 0 As Numeric
 Local _cPerg:= 'ROMS004' As Char
 Local _cQuery:= '' As Char
 Local _oPrint As Object
 Local _nI:= 0 As Numeric  
 Local _aCargas := {} As Array

 Private _cAlias  := GetNextAlias() As Char
 Private _nPagAux := 0 As Numeric
 Private _nLinPont:= 185 As Numeric
 //Configuracoes para "Exporta para PDF" / Envio via e-mail
 Private _nColMax	 := 3280 As Numeric
 Private _nColFimPDH := _nColMax-940 As Numeric
 Private _oFontCour  := TFont():New('Courier new',, 15,,.F.) As Object
 Private _oFont1Cour := TFont():New('Courier new',, 14,,.T.) As Object
 Private _oFont2Cour := TFont():New('Courier new',, 12,,.T.) As Object
 //Configuracoes para "Exporta para PDF" / Envio via e-mail
 Private _bCoordRect := {|L| { L-28 , _nColIni , L+2 , _nColMax } } As Block
 Private _aCliente   := {} As Array // Para contar os pontos de atendimento
 Private _cTpOper24  := "" As Char

 Private _cObsCarga  := "" As Char
 Private _lAutoRel   := .F. As Logical

 If VALTYPE(_lLAutoRel) = "L"
    _lAutoRel:=_lLAutoRel
 EndIf

 Default _lshow := .T.

 SET DATE FORMAT TO "DD/MM/YYYY"

 If !_lAutoRel .AND. !Pergunte(_cPerg)
     Return .F.
 EndIf

 //Log de execução
 If !_lAutoRel

     u_itlogacs()

 EndIf

 _cQuery := " SELECT DAK_FILIAL, DAK_COD,DAK_I_CARG,DAK_DATA,DAK_HORA,DAK_I_REDP, "
 _cQuery += " DAK_I_REDP, DAK_I_RELO, DAK_I_OPER, DAK_I_OPER, DAK_I_OPLO ,DAK_MOTORI, "
 _cQuery += " DAK_CAMINH , DAK_USERGI , DAK_I_TPCA, DAK_I_OBS, DAI_PEDIDO,"
 _cQuery += " CASE "
 _cQuery += "     WHEN C5_I_OPER = '24' THEN 'B' "
 _cQuery += "     Else 'A' "
 _cQuery += " END AS ORDIMP "
 _cQuery += " FROM  " + RetSQLName('DAK') +" DAK, " + RetSQLName('DAI') +" DAI, "+ RetSQLName('SC5') +" SC5 "
 _cQuery += " WHERE "+ RetSQLCond('DAK')
 _cQuery += " AND " + RetSQLCond('DAI')
 _cQuery += " AND " + RetSQLCond('SC5')
 _cQuery += " AND DAK_FILIAL = DAI_FILIAL AND DAK_COD = DAI_COD AND DAI_FILIAL = C5_FILIAL AND DAI_PEDIDO = C5_NUM "
 _cQuery += " AND DAK.DAK_COD BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
 _cQuery += " ORDER BY ORDIMP,DAK_FILIAL, DAK_COD "

 If Select(_cAlias) > 0
     (_cAlias)->( DBCloseArea() )
 EndIf

 If _lAutoRel
    MPSysOpenQuery( _cQuery , _cAlias)
 Else
    LjMsgRun( "Lendo dados..." , "Aguarde!" , {|| MPSysOpenQuery( _cQuery , _cAlias) } )
 EndIf


 If (_cAlias)->(!Eof())
    // Cria Arquivo do Relatório
    _lMostraPDF:=.T.

    If !_lshow //Se veio parametro para não apresentar mensagem não mostra o pdf e só deixa o arquivo no servidor
          _lMostraPDF := .F.
     EndIf
     _cPathSrv:=GETMV("MV_RELT",,"\SPOOL\")

     If _lAutoRel
        _cFilename:=Lower(ROMS004NameFile(MV_PAR01))
        //FWMsPrinter(): New (< cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
        _oPrint := FWMsPrinter():New(_cFilename, IMP_PDF   , .T.               , _cPathSrv       , .T.             ,            ,                ,            , .T. )
     Else
        _cFilename:=ROMS004NameFile("")
        //FWMsPrinter(): New (< cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
        _oPrint := FWMsPrinter():New(_cFilename, IMP_PDF   , .T.               , _cPathSrv       ,                 ,            ,                ,            , .T. )

         If !(_oPrint:nModalResult == PD_OK)
             _oPrint:Deactivate()
             Return
         EndIf

     EndIf

     // Configura modo Paisagem de Impressao
     _oPrint:SetResolution(78)
     _oPrint:SetLandscape()
     // Define impressao em papel A4
     _oPrint:SetPaperSize(DMPAPER_A4)
     _oPrint:SetMargin(0,0,0,0)	// nEsquerda, nSuperior, nDireita, nInferior
     // Se enviar por e-mail nao abre o arquivo apos a impressao
     If _lAutoRel //Aqui é sempre Exporta PDF via e-mail

 //**** Configuracoes para via WF de Carga **********************************************************************************
        _oPrint:SetViewPDF(_lMostraPDF)
        _oPrint:cPathPDF := _cPathSrv	// Caso seja utilizada impressão em IMP_PDF
 //**** Configuracoes para via WF de Carga **********************************************************************************

     ElseIf !_lAutoRel .AND. !(_oPrint:CPRINTER == "PDF")// _oPrint:CPRINTER == "PDF" quer dizer Exporta PDF via seleção na Tela

 //**** Configuracoes para "Envia para Spool de impressao **********************************************************************************
        _nColMax	   := 3230//3280
        _nColFimPDH := _nColMax-900
        _oFontCour  := TFont():New('Courier new',, 12,,.F.)
        _oFont1Cour := TFont():New('Courier new',, 12,,.T.)
        _oFont2Cour := TFont():New('Courier new',, 11,,.T.)
 //**** Configuracoes para "Envia para Spool de impressao **********************************************************************************

     EndIf

     While (_cAlias)->(!Eof())
        // Controle para não permitir a reimpressão de cargas já impressas.
        _nI := Ascan(_aCargas, {|x| x[1] == (_cAlias)->DAK_FILIAL .And. x[2] == (_cAlias)->DAK_COD} )
        If _nI > 0
           (_cAlias)->(DBSkip())
           Loop
        Else
           Aadd(_aCargas, {(_cAlias)->DAK_FILIAL, (_cAlias)->DAK_COD})
        EndIf

        _cObsCarga  := U_ROMS004O((_cAlias)->DAK_FILIAL, (_cAlias)->DAK_COD)

         _oPrint:StartPage()			//Inicia uma página para impressão

         // Verifica e retorna se existir pedidos de vendas com data crítica.
         _cTpOper24 := ROMS004Dtc((_cAlias)->DAK_FILIAL, (_cAlias)->DAK_COD)

         // Cabecalho
         ROMS004Cab( @_oPrint , @_nLinha )

         // Dados da Carga
         ROMS004Crg( @_oPrint , @_nLinha , _cAlias )

         // Dados da Ordem de Carga
         If _lAutoRel
            ROMS004Cmp( @_oPrint , @_nLinha , _cAlias )
         Else
            LjMsgRun( "Lendo Carga: "+(_cAlias)->DAK_COD , "Aguarde!" , {|| ROMS004Cmp( @_oPrint , @_nLinha , _cAlias ) } )
         EndIf

         // Finaliza página
         _oPrint:EndPage()

        (_cAlias)->( DBSkip() )
     EndDo

     (_cAlias)->( DBCloseArea() )
     
     If _lAutoRel

        If IsInCallStack("OM200Email")
           _lMostraPDF := .F.
        EndIf

        _oPrint:lViewPDF := _lMostraPDF
        _oPrint:Preview()
        FreeObj(_oPrint)

        If _lshow //Se não é webservice precisa copiar o arquivo para o servidor
             _cOrigem :=_cPathSrv+_cFilename
             _cDestino:=_cPathSrv
             If !IsinCallStack("OM200Email")
                 CpyS2TEx(_cOrigem,_cDestino,.F.) // Terminal To Server
             EndIf
             _cFilename:=_cPathSrv + _cFilename
        Else //Se é webservice precisa retornar com path do servidor
             _cFilename:=GETMV("MV_RELT",,"\SPOOL\") + _cFilename
        EndIf

         If File(_cFilename)
            _aDatFile := directory(_cFilename)
            _nTamanho := If(Len(_aDatFile)=0,0,_aDatFile[1][2])
            If Len(_aDatFile)=0 .AND. (_nHandle:=Fopen(_cFilename, 0 )) > 0
               _nTamanho:= FSeek(_nHandle, 0, 2) //Posiciona no fim do arquivo para pegar o tamanho
               fClose(_nHandle)
            EndIf
         Else
            _nTamanho := 0
         EndIf
         If _nTamanho = 0
            _cFilename:= " ("+_cFilename+") nao Localizado no envio do email"
            U_MostraCalls()
            Return .F.
         EndIf

     Else
         LjMsgRun( "Gerando a visualização..." , "Aguarde!" , {|| _oPrint:Preview() } )//Visualiza antes de imprimir
         _cFilename:=_cPathSrv + _cFilename
     EndIf

 Else

     Return .F.

 EndIf

 If _cFilename # nil
    _cFileRelName:=STRTRAN( UPPER(_cFilename), ".PDF", ".REL")
    If File(_cFileRelName)
       FErase(_cFileRelName)
    EndIf
 EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: ROMS004Cab
Autor-------------: Alexandre Villar
Data da Criacao---: 24/02/2014
Descrição---------: Função para construir o cabeçalho da página
Parametros--------: _oPrint := Objeto de impressão do relatório
------------------: _nLinha := Controle de posicionamento de linhas
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS004Cab( _oPrint As Object, _nLinha As Numeric )
 Local _nAjusteCb := 0 As Numeric
 Local _oFont10	:= TFont():New( "Arial" ,, 14 ,,.T. ) As Object
 Local _oFont18	:= TFont():New( "Arial" ,, 28 ,,.T. ) As Object
 Local _oFont16	:= TFont():New( "Arial" ,, 16 ,,.T. ) As Object
 Local _nColIni	:= 0100 As Numeric

 _nLinha := 50
 _nPagAux++

 If ! Empty(_cTpOper24)
    _nAjusteCb := 400
 EndIf

 _oPrint:Line( _nLinha		, _nColIni , _nLinha		, _nColMax )
 _nlinha += 010
 _oPrint:SayBitmap( _nLinha	, _nColIni + 020 , 'lgrl01.bmp' , 300 , 120 ) // Imagem tem que estar abaixo do RootPath
 _nSomaCol:=1115//1235
 _oPrint:Say( _nLinha+60 , _nColIni +_nSomaCol - _nAjusteCb, 'Ordem de Carga: '+(_cAlias)->DAK_COD, _oFont18 )

 _oPrint:Say( _nLinha+60 , _nColIni +_nSomaCol + 1000 - _nAjusteCb, _cTpOper24 , _oFont18 )

 _oPrint:Say( _nLinha+130, _nColIni + 1200	 , 'Empresa: '+ cEmpAnt +' - '+ Alltrim( SM0->M0_NOME ) +' / Filial: '+ cFilAnt +' - '+ Alltrim( SM0->M0_FILIAL ) , _oFont10 )
 _oPrint:Say( _nLinha+130, _nColIni +_nSomaCol + 1000, 'Viagem RDC: '+(_cAlias)->DAK_I_CARG, _oFont16 )

 _oPrint:SayAlign( _nLinha,_nColFimPDH, 'Página: '+ StrZero(_nPagAux,3)	, _oFont10 ,900,100,, 1 )
 _nLinha += 050
 _oPrint:SayAlign( _nLinha,_nColFimPDH, 'Data: '+ DtoC( Date() )	    , _oFont10 ,900,100,, 1 )
 _nLinha += 050
 _oPrint:SayAlign( _nLinha,_nColFimPDH, 'Hora: '+ Time()			    , _oFont10 ,900,100,, 1 )

 _nLinha += 050
 _oPrint:Line( _nLinha , _nColIni , _nLinha, _nColMax )

 _nLinha += 050

Return

/*
===============================================================================================================================
Programa----------: ROMS004Crg
Autor-------------: Alexandre Villar
Data da Criacao---: 03/12/2014
Descrição---------: Função para imprimir os dados da Carga
Parametros--------: _oPrint As Object, _nLinha As Numeric, _cAlias As Char
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS004Crg( _oPrint As Object, _nLinha As Numeric, _cAlias As Char)
 Local _oFont08	:= TFont():New( "Arial" ,, 14 ,, .F.  ) As Object
 Local _oFont08b  := TFont():New( "Arial" ,, 15 ,, .T. ,,,, .T. , .T. ) As Object
 Local _oFont10	:= TFont():New( "Arial" ,, 12 ,, .F.  ) As Object
 Local _cPlacas	:= '' As Char
 Local _nColIni	:= 0100 As Numeric
 Local _nCol001	:= _nColIni + 0400 As Numeric
 Local _nCol002	:= _nColIni	+ 1850 As Numeric

 DAK->( DBSetOrder(1) )
 If DAK->( DBSeek( FwXFilial("DAK") + (_cAlias)->DAK_COD ) )

     _oPrint:Say( _nLinha , _nCol002 + 620	, 'Data / Hora da Carga: '+DtoC( DAK->DAK_DATA ) +" / "+ DAK->DAK_HORA, _oFont08 )

     If !Empty(DAK->DAK_I_REDP) .AND. SA2->( DBSeek( FwXFilial('SA2') + DAK->DAK_I_REDP+DAK->DAK_I_RELO ) )
        _oPrint:Say( _nLinha , _nColIni	, 'Transp. de Redespacho: '					  		 												   				, _oFont08 )
        _oPrint:Say( _nLinha , _nCol001	, Alltrim(SA2->A2_NOME)																		  		 					, _oFont08 )
        _oPrint:Say( _nLinha , _nCol002  , 'CPF/CNPJ: '+Transform( SA2->A2_CGC , IIF(Len(Alltrim(SA2->A2_CGC))>11,'@R! NN.NNN.NNN/NNNN-99','@R 999.999.999-99') )	, _oFont08 )
        _nLinha += 040
     EndIf

     If !Empty(DAK->DAK_I_OPER) .AND. SA2->( DBSeek( FwXFilial('SA2') + DAK->DAK_I_OPER+DAK->DAK_I_OPLO ) )
        _oPrint:Say( _nLinha , _nColIni	, 'Operador Logistico: '					  		 												   				, _oFont08 )
        _oPrint:Say( _nLinha , _nCol001	, Alltrim(SA2->A2_NOME)																		  		 					, _oFont08 )
        _oPrint:Say( _nLinha , _nCol002  , 'CPF/CNPJ: '+Transform( SA2->A2_CGC , IIF(Len(Alltrim(SA2->A2_CGC))>11,'@R! NN.NNN.NNN/NNNN-99','@R 999.999.999-99') )	, _oFont08 )
        _nLinha += 040
     EndIf

     DA4->( DBSetOrder(1) )
     If DA4->( DBSeek( FwXFilial("DA4") + DAK->DAK_MOTORI ) )

         _cSeekSA2:=DA4->( DA4_FORNEC + IF(!Empty(DAK->DAK_I_LJTR),DAK->DAK_I_LJTR,DA4->DA4_LOJA)   )

         DAI->( DbSetOrder(1) )
         DAI->( DBSeek( FwXFilial("DAI") + DAK->DAK_COD ) )

         SF2->( DbSetOrder(1) )
         If SF2->( DbSeek( FwXFilial("SF2") + DAI->(DAI_NFISCA+DAI_SERIE) ) ) .AND. !Empty(SF2->F2_I_CTRA)
              _cSeekSA2:=SF2->F2_I_CTRA + SF2->F2_I_LTRA
         EndIf

         SA2->( DBSetOrder(1) )
         If SA2->( DBSeek( FwXFilial('SA2') + _cSeekSA2 ) )

             _oPrint:Say( _nLinha , _nColIni	, 'Transportadora: '					  		 															, _oFont08 )
             _oPrint:Say( _nLinha , _nCol001	, Alltrim(SA2->A2_NOME)																			  		 		, _oFont08 )
             _oPrint:Say( _nLinha , _nCol002 , 'CPF/CNPJ: '+Transform( SA2->A2_CGC , IIF(Len(Alltrim(SA2->A2_CGC))>11,'@R! NN.NNN.NNN/NNNN-99','@R 999.999.999-99') )	, _oFont08 )

             _nLinha += 040

             DA3->( DBSetOrder(1) )
             If DA3->( DBSeek( FwXFilial("DA3") + DAK->DAK_CAMINH ) )

                 If	DA3->DA3_I_TPVC == "2" .OR. DA3->DA3_I_TPVC == "4"//Caminhao ou Utilitario

                     _cPlacas := Alltrim( DA3->DA3_PLACA )+'/'+DA3->DA3_ESTPLA

                 ElseIf DA3->DA3_I_TPVC == "1" //Carreta

                     _cPlacas := 'Cavalo: '+Alltrim( DA3->DA3_I_PLCV )+'/'+DA3->DA3_I_UFCV+' ; Vagão: '+IIF(!Empty(DA3->DA3_I_PLVG),Alltrim( DA3->DA3_I_PLVG )+'/'+DA3->DA3_I_UFVG,Alltrim( DA3->DA3_PLACA )+'/'+DA3->DA3_ESTPLA)

                 ElseIf DA3->DA3_I_TPVC == "3" .OR. DA3->DA3_I_TPVC == "5"  //BITREM OU BITREM

                     _cPlacas := 'Cavalo: '+Alltrim( DA3->DA3_I_PLCV )+'/'+DA3->DA3_I_UFCV+' ; Vagão 1:'+Alltrim( DA3->DA3_I_PLVG )+'/'+DA3->DA3_I_UFVG+' ; Vagão 2:'+Alltrim( DA3->DA3_PLACA )+'/'+DA3->DA3_ESTPLA

                 EndIf

             EndIf

             _oPrint:Say( _nLinha , _nColIni	, 'Motorista: '	 , _oFont08 )

             _oPrint:Say( _nLinha , _nCol001	, Alltrim(DA4->DA4_NOME ) , _oFont08b )

             _nLinha += 050

             _oPrint:Say( _nLinha , _nColIni	, 'Telefone: '	 , _oFont08 )

             _oPrint:Say( _nLinha , _nCol001	, "(" + DA4->DA4_DDD + ") " + Alltrim(DA4->DA4_TEL) + Iif(Empty(DA4->DA4_TELREC),"", "/(" + DA4->DA4_I_DDD2 + ") " + Alltrim(DA4->DA4_TELREC))	, _oFont08 )

             _oPrint:Say( _nLinha , _nCol002	, 'Placas: '+ _cPlacas				, _oFont08 )

             _nLinha += 050

             _oPrint:Say( _nLinha , _nColIni	, 'Carregado em:'	  									, _oFont08 )
             _oPrint:Say( _nLinha , _nCol001	, '______/______/____________   às   ______ : ______'	, _oFont08 )

         EndIf

     EndIf

     _oPrint:Say( _nLinha , _nCol002	, 'Resp. Logist.: '+ UsrFullName( SubStr( Embaralha( DAK->DAK_USERGI, 1 ), 3, 6 ) ), _oFont08 )

 Else

     _oPrint:Say( _nLinha , _nColIni , 'Não foi possível identificar os dados da carga: '+ Alltrim( (_cAlias)->DAK_COD ) , _oFont10 )

 EndIf

 _nLinha += 030
 _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )
 _nLinha += 050

Return

/*
===============================================================================================================================
Programa----------: ROMS004Cmp
Autor-------------: Alexandre Villar
Data da Criacao---: 03/12/2014
Descrição---------: Função para imprimir os dados da composição da Carga
Parametros--------: _oPrint As Object, _nLinha As Numeric, _cAlias As Char
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS004Cmp( _oPrint As Object, _nLinha As Numeric, _cAlias As Char)
 Local _aRota      := {} As Array
 Local _aCondPG    := {} As Array
 Local _aProduto   := {} As Array
 Local _a1Produto  := {} As Array
 Local _a3Produto  := {} As Array
 Local _aResumo    := {} As Array
 Local _aTpCarga   := {} As Array
 Local _aParcGer   := {} As Array
 Local _dEmsPed    := StoD('') As Date
 Local _cConPgt    := '' As Char
 Local _cCond      := '' As Char
 Local _cNomCli    := "" As Char
 Local _cMunCli    := "" As Char
 Local _cEstCli    := "" As Char
 Local _cMsgObs    := '' As Char
 Local _cCgcMot    := '' As Char
 Local _cRGMot     := '' As Char
 Local _nVlrPed    := 0 As Numeric
 Local _nPonEnt    := 0 As Numeric
 Local _nCont      := 0 As Numeric
 Local _nVlToPed   := 0 As Numeric
 Local _cGrupoPV   := "" As Char
 Local _oFont08    := TFont():New( "Arial",, 14 ,, .F. ) As Object 
 Local _oFont12    := TFont():New( "Arial",, 12 ,, .F. ) As Object
 Local _oFontCN    := TFont():New( "Arial",, 08 ,, .F. ) As Object
 Local _oFontIT    := _oFontCour As Object
 Local _nLinMax    := 2380 As Numeric
 Local _nColIni    := 0100 As Numeric
 Local _nI         := 0 As Numeric  
 Local _cBairroCli := "" As Char
 Local _cPedCarr   := "" As Char
 Local _cPedFat    := "" As Char
 Local _cCgcCli    := "" As Char
 Local _cShelf     := "" As Char
 Local _nPosCli    := 0 As Numeric
 Local _nPosRes    := 0 As Numeric
 Local x           := 0 As Numeric
 Local y           := 0 As Numeric
 Local _nValor     := 0 As Numeric
 Local _cValor     := "" As Char
 Local _cLocal     := "" As Char
 Local _cDesGrFa   := "" As Char
 Local _cDesFami   := "" As Char
 Local cComboTpCa  := "" As Char
 
 Private _nCol002  := 0 As Numeric
 Private _nCol003  := 0 As Numeric
 Private _nCol004  := 0 As Numeric
 Private _nCol005  := 0 As Numeric
 Private _nCol006  := 0 As Numeric
 Private _nCol007  := 0 As Numeric
 Private _nCol008  := 0 As Numeric
 Private _nCol009  := 0 As Numeric
 Private _nCol010  := 0 As Numeric
 Private _nCol011  := 0 As Numeric
 Private _nCol012  := 0 As Numeric
 Private _nTotQtd  := 0 As Numeric
 Private _nTotQtd2 := 0 As Numeric
 Private _nTotQtd3 := 0 As Numeric
 Private _nTotPeso := 0 As Numeric
 Private _lResumoporProduto := .F. As Logical

 SX3->( DBSetOrder(2) )
 If SX3->( DBSeek( "DAK_I_TPCA" ) )
    cComboTpCa := X3Cbox()
 EndIf

 //A funcao StrTokArr() tem o objetivo de retornar um array, de acordo com os dados passados como parametro para a funcao
 _aTpCarga := StrTokArr( cComboTpCa , ';' )

 SC6->( DbSetOrder(1) )
 DAK->( DBSetOrder(1) )
 If DAK->( DBSeek( FwXFilial("DAK") + (_cAlias)->DAK_COD ) )

 //	_nPonEnt := DAK->DAK_PTOENT


    DA4->( DBSetOrder(1) )
    If DA4->( DBSeek( FwXFilial("DA4") + DAK->DAK_MOTORI ) )

        _cCGCMOT:= Transform( Alltrim( DA4->DA4_CGC ) , IIF( Len( Alltrim(DA4->DA4_CGC) ) > 11 , '@R! NN.NNN.NNN/NNNN-99' , '@R 999.999.999-99' ) )
        _cRGMOT := Alltrim( DA4->DA4_RG )

    EndIf

    If Len( Alltrim( DAK->DAK_I_TPCA ) ) > 0

        _cMsgObs  := Alltrim( _aTpCarga[ Val(DAK->DAK_I_TPCA) ] ) + IIF( DAK->DAK_I_TPCA == '2' , ' ( Estrechar inclusive os remontes )' , '' )
        _cMsgObs  := 'Carga: '+ SubStr( _cMsgObs , AT( "=" , _cMsgObs ) + 1 )

    EndIf

    //====================================================================================================
    // Localizando os dados da carga
    //====================================================================================================
    _aCliente:={}//Para contar os pontos de atendimento
    _aCliente:={}//Para contar os pontos de atendimento

    DAI->( DBSetOrder(1) )
    If DAI->( DBSeek( FwXFilial("DAI") + DAK->DAK_COD ) )

        While DAI->( !EOF() ) .And. DAI->( DAI_FILIAL + DAI_COD ) == FwXFilial("DAI") + DAK->DAK_COD

            //====================================================================================================
            // Compondo o roteiro
            //====================================================================================================
            If Ascan( _aRota , DAI->DAI_ROTEIR ) == 0
                AADD( _aRota , DAI->DAI_ROTEIR )
            EndIf

            _cGrupoPV := "A"
            SC5->( DbSetOrder(1) )
            If SC5->( DbSeek( FwXFilial("SC5") + DAI->DAI_PEDIDO ) )
                _dEmsPed := SC5->C5_EMISSAO
                _cConPgt := SC5->C5_CONDPAG
                If SC5->C5_I_OPER == '24'
                   _cGrupoPV := "B"
                EndIf
            EndIf

            SC9->( DbSetOrder(1) )
            SC9->( DbSeek( FwXFilial("SC9") + DAI->DAI_PEDIDO ) )
            SF2->( DbSetOrder(1) )
            SF2->( DbSeek( FwXFilial("SF2") + SC9->( C9_NFISCAL + C9_SERIENF ) ) )
            SCV->( DBSetOrder(1) )
            If SCV->( DBSeek( FwXFilial("SCV") + DAI->DAI_PEDIDO ) )

                While SCV->( !EOF() ) .and. SCV->CV_PEDIDO == DAI->DAI_PEDIDO

                    _cCond := If( Empty(_cCond) , "" , _cCond + "/" ) + SCV->CV_FORMAPG

                    If ( _nPos := aScan( _aCondPG , { |x| x[1] == _cCond } ) ) == 0
                        aAdd( _aCondPG , { SCV->CV_FORMAPG , SCV->CV_DESCFOR , ( ( SF2->F2_VALBRUT * SCV->CV_RATFOR ) / 100 ) } )
                    Else
                        _aCondPG[_nPos][03] += ( SF2->F2_VALBRUT * SCV->CV_RATFOR ) / 100
                    EndIf

                    SCV->( DBSkip() )
                EndDo

            EndIf

            _cNomCli	   := ''
            _cMunCli	   := ''
            _cEstCli	   := ''
            _cBairroCli := ''
            _cCliLoja   := ''
            _cNomRedCli	:= ''
            _cShelf     := ''

            //====================================================================================================
            // Verifica se o Tipo é "Devolução" para buscar dados do Cliente/Fornecedor
            //====================================================================================================

            _cChave:=""
            If SF2->F2_TIPO $ "B/D"

                SA2->( DbSetOrder(1) )
                If SA2->( DbSeek( FwXFilial("SA2") + DAI->( DAI_CLIENT + DAI_LOJA ) ) )
                    _cNomCli    := "FO: "+Alltrim(SA2->A2_NOME)
                    _cMunCli    := Alltrim( SA2->A2_MUN)
                    _cEstCli    := Alltrim( SA2->A2_EST)
                    _cBairroCli := Alltrim(SA2->A2_BAIRRO)
                    _cNomRedCli := Alltrim(SA2->A2_NOME)
                    _cCgcCli    := Transform(SA2->A2_CGC,PesqPict("SA2","A2_CGC") )
                    _cShelf     := ""
                EndIf

            Else

                SA1->( DbSetOrder(1) )
                If SA1->( DbSeek( FwXFilial("SA1") + DAI->( DAI_CLIENT + DAI_LOJA ) ) )
                   _cNomCli   := "CL: "+Alltrim(SA1->A1_NOME)
                   _cMunCli   := Alltrim( SA1->A1_MUN)
                   _cEstCli   := Alltrim( SA1->A1_EST)
                   _cBairroCli:= Alltrim(SA1->A1_BAIRRO)
                   _cNomRedCli:= Alltrim(SA1->A1_NOME)
                   _cCgcCli   := Transform(SA1->A1_CGC,PesqPict("SA1","A1_CGC") )
                   _cShelf    := Alltrim( SA1->A1_I_SHLFP )
                EndIf

            EndIf
            _cCliLoja:= DAI->( DAI_CLIENT + DAI_LOJA )
            _cChave  := DAI->( DAI_CLIENT + DAI_LOJA )

            If DAI->DAI_I_OPER="1" .AND. !Empty(DAK->DAK_I_OPER) .AND. SA2->( DBSeek( FwXFilial('SA2') + DAK->DAK_I_OPER+DAK->DAK_I_OPLO ) )

                If  !Empty(DAI->DAI_I_OPLO)

                    If SA2->( DBSeek( FwXFilial('SA2') + DAI->DAI_I_OPLO+DAI->DAI_I_LOPL ) )

                        _cCliLoja  := DAI->DAI_I_OPLO+DAI->DAI_I_LOPL
                        _cNomCli   := "OP: "+Alltrim(SA2->A2_NOME)
                        _cMunCli   := Alltrim(SA2->A2_MUN)
                        _cEstCli   := Alltrim(SA2->A2_EST)
                        _cChave    := DAI->DAI_I_OPLO+DAI->DAI_I_LOPL
                        _cBairroCli:= Alltrim(SA2->A2_BAIRRO)
                        _cNomRedCli:= Alltrim(SA2->A2_NOME)
                        _cCgcCli   := Transform(SA2->A2_CGC,PesqPict("SA2","A2_CGC") )

                    EndIf

                Else

                    _cCliLoja  := DAK->DAK_I_OPER+DAK->DAK_I_OPLO
                    _cNomCli   := "OP: "+Alltrim(SA2->A2_NOME)
                    _cMunCli   := Alltrim(SA2->A2_MUN)
                    _cEstCli   := Alltrim(SA2->A2_EST)
                    _cChave    := DAK->DAK_I_OPER+DAK->DAK_I_OPLO
                    _cBairroCli:= Alltrim(SA2->A2_BAIRRO)
                    _cNomRedCli:= Alltrim(SA2->A2_NOME)
                    _cCgcCli   := Transform(SA2->A2_CGC,PesqPict("SA2","A2_CGC") )

               EndIf

            EndIf

            If DAI->DAI_I_REDP="1" .AND. !Empty(DAK->DAK_I_REDP) .AND. SA2->( DBSeek( FwXFilial('SA2') + DAK->DAK_I_REDP+DAK->DAK_I_RELO ) )

                If !Empty(DAI->DAI_I_TRED)


                    If SA2->( DBSeek( FwXFilial('SA2') + DAI->DAI_I_TRED+DAI->DAI_I_LTRE ) )

                       _cCliLoja	 := DAI->DAI_I_TRED+DAI->DAI_I_LTRE
                       _cNomCli 	 := "TR: "+Alltrim(SA2->A2_NOME)
                       _cMunCli 	 := Alltrim(SA2->A2_MUN)
                       _cEstCli 	 := Alltrim(SA2->A2_EST)
                       _cChave  	 := DAI->DAI_I_TRED+DAI->DAI_I_LTRE
                       _cBairroCli:= Alltrim(SA2->A2_BAIRRO)
                       _cNomRedCli:= Alltrim(SA2->A2_NOME)
                       _cCgcCli   := Transform(SA2->A2_CGC,PesqPict("SA2","A2_CGC") )

                    EndIf

               Else

                    _cCliLoja  := DAK->DAK_I_REDP+DAK->DAK_I_RELO
                    _cNomCli   := "TR: "+Alltrim(SA2->A2_NOME)
                    _cMunCli   := Alltrim(SA2->A2_MUN)
                    _cEstCli   := Alltrim(SA2->A2_EST)
                    _cChave    := DAK->DAK_I_REDP+DAK->DAK_I_RELO
                    _cBairroCli:= Alltrim(SA2->A2_BAIRRO)
                    _cNomRedCli:= Alltrim(SA2->A2_NOME)
                    _cCgcCli   := Transform(SA2->A2_CGC,PesqPict("SA2","A2_CGC") )

               EndIf

            EndIf

            //Pega a menor sequencia de cada cliente loja
            If !Empty(_cChave) .AND. (_nPosCli:=aScan(_aCliente,{|C| C[1]==_cChave } )) = 0
               AAdd(_aCliente, {_cChave,VAL(DAI->DAI_SEQUEN)} )
            Else
               If VAL(DAI->DAI_SEQUEN) < _aCliente[_nPosCli,2]
                  _aCliente[_nPosCli,2]:=VAL(DAI->DAI_SEQUEN)
               EndIf
            EndIf
            //Pega a menor sequencia de cada cliente loja

            // Verifica e inclui os dados para montar o resumo do relatório
            If Ascan( _aResumo , { |x| x[1] == DAI->DAI_PEDIDO } ) == 0

               cTipoCarga:= IF(DAI->DAI_I_TIPC="1","Plt Chep",;
                            IF(DAI->DAI_I_TIPC="2","Estivada",;
                            IF(DAI->DAI_I_TIPC="3","Plt PBR",;
                            IF(DAI->DAI_I_TIPC="4","Descartavel",;
                            IF(DAI->DAI_I_TIPC="5","Plt Chep Ret",;
                            IF(DAI->DAI_I_TIPC="6","Plt PBR Ret","            "))))))
               _cPedCarr := IF(SC5->C5_I_TRCNF='S' .AND. !Empty(SC5->C5_I_PDPR),SC5->C5_I_FLFNC+"-"+SC5->C5_I_PDPR, DAI->DAI_FILIAL+"-"+DAI->DAI_PEDIDO )
               _cPedFat  := IF(SC5->C5_I_TRCNF='S' .AND. !Empty(SC5->C5_I_PDFT),SC5->C5_I_FILFT+"-"+SC5->C5_I_PDFT, SPACE(Len(DAI->DAI_FILIAL+"-"+DAI->DAI_PEDIDO)) )

               //Se for pedido de operação triangular indica o pedido de faturamento vinculado
               If SC5->C5_I_OPTRI == "R"  .and. !Empty(SC5->C5_I_PVFAT)
                  _cPedFat := SC5->C5_I_PVFAT
               EndIf

               If Empty(_cPedFat)
                  If SC5->C5_I_TRCNF == "S"
                     _cPedFat := "TROCA NF"
                  ElseIf SC5->C5_I_OPER == "42"
                     _cPedFat := "TRIANGU."
                  EndIf
               EndIf

               SC6->( DBSeek( FwXFilial("SC6") + DAI->DAI_PEDIDO ) )
               _cLocal := SC6->C6_LOCAL
               While SC6->(!Eof()) .And. SC6->C6_NUM == DAI->DAI_PEDIDO
                  _nValor += SC6->C6_VALOR
                  SC6->(DBSkip())
               ENDDO

               _cValor := "R$" + transform(_nValor, "@E 999,999.99")

               AADD( _aResumo , {SC9->C9_NFISCAL  ,;// 01 //N.Fiscal'
                                 _cCgcCli         ,;// 02 //Redesp./Op.Log.'
                                 LEFT(_cNomCli,40),;// 03 //Código/Nome
                                 LEFT(_cMunCli,20),;// 04 //Destino'
                                 _cEstCli	        ,;// 05 //UF'
                                 _cPedCarr        ,;// 06 //PV de Carregamento
                                 cTipoCarga       ,;// 07 //Tipo de carga'
                                 _cCliLoja        ,;// 08 //Codigo + Loja do Destinatario
                                 DAI->DAI_SEQUEN  ,;// 09 //Para ordernar por nova sequncia mais velha sequencia
                                 _cPedFat         ,;// 10 //PV de Faturamento
                                 _cLocal          ,;// 11 //Armazem
                                 _cValor          })// 12 //Valor total a nota

            EndIf

            _nVlToPed := 0
            _nValor	  := 0


            SD2->( DBSetOrder(3) )

            If SD2->( DBSeek( FwXFilial("SD2") + SF2->( F2_DOC+ F2_SERIE ) ) )

                While SD2->( !EOF() ) .AND. SD2->D2_DOC == SF2->F2_DOC .AND. SD2->D2_SERIE == SF2->F2_SERIE

                    If Alltrim(Posicione("SF4",1,FwXFilial("SF4") + SD2->D2_TES,"SF4->F4_DUPLIC")) == 'S'
                        _nVlToPed += SD2->D2_VALBRUT
                    EndIf

                SD2->( DBSkip() )
                EndDo

            EndIf

            _nVlrPed := 0
            SD2->( DBSetOrder(3) )
            If SD2->( DBSeek( FwXFilial("SD2") + SF2->( F2_DOC + F2_SERIE ) ) )

                While SD2->( !EOF() ) .AND. SD2->( D2_FILIAL + D2_DOC + D2_SERIE ) == FwXFilial("SD2") + SF2->( F2_DOC + F2_SERIE )

                    If Alltrim( Posicione( 'SF4' , 1 , FwXFilial('SF4') + SD2->D2_TES , 'F4_DUPLIC' ) ) == 'S'
                        _nVlrPed += SD2->D2_VALBRUT
                    EndIf

                SD2->( DBSkip() )
                EndDo

            EndIf

            // Compondo os dados do produto
            SC9->( DBSetOrder(1) )
            SB1->( DBSetOrder(1) )
            SC6->( DbSetOrder(1) )
            If SC6->( DBSeek( FwXFilial("SC6") + DAI->DAI_PEDIDO ) )

               While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == FwXFilial("SC6") + DAI->DAI_PEDIDO

                    SB1->( DBSeek( FwXFilial("SB1") + SC6->C6_PRODUTO ) )

                    SC9->( DBSeek( FwXFilial("SC9") + SC6->C6_NUM + SC6->C6_ITEM ) )
                    If MV_PAR03 == 4 //DESTIVADO POR ENQUANTO
                       _cLocal:=SC9->C9_LOCAL
                    Else
                       _cLocal:=""
                    EndIf

                    _cDescItem  := Alltrim(IF(LEFT(SC6->C6_PRODUTO,2)="08","zz","")+SB1->B1_DESC)//Coloca zz na frente da Descrisão do item PALLET para ele ficar por ultimo na lista sempre
                    _nPesoBruto := IF(!Empty(SC6->C6_I_PTBRU),SC6->C6_I_PTBRU,(SB1->B1_PESBRU*SC6->C6_QTDVEN))
                    _cDesGrFa   := IF(LEFT(SC6->C6_PRODUTO,2)="08","zz","") //Coloca zz na frente do item PALLET para ele ficar por ultimo na lista sempre
                    _cDesFami   := ""
                    If !Empty(SB1->B1_I_BIGRP)
                       _aRet    := FWGetSX5("ZA",SB1->B1_I_BIGRP)
                       If !Empty(_aRet)
                          _cDesGrFa:= _cDesGrFa + Alltrim(_aRet[1,4])
                       EndIf
                    EndIf
                    If !Empty(SB1->B1_I_BIFAM)
                       _aRet    := FWGetSX5("ZB",SB1->B1_I_BIFAM)
                       If !Empty(_aRet)
                          _cDesFami:= Alltrim(_aRet[1,4])
                       EndIf
                    EndIf
 
                    If MV_PAR03 == 3  .OR. MV_PAR03 == 4// Agrupamento utilizado apenas na emissão do relatório Ordem de Carga por PONTO DE ENTREGA.
                       If ( nPos := Ascan( _a3Produto , { |x| x[22] + x[24] + x[25] == SC6->C6_PRODUTO + SC9->C9_LOTECTL + _cCliLoja +_cGrupoPV +_cLocal } ) ) == 0
                          AADD(_a3Produto,{	SC6->C6_PRODUTO						                      ,; //01 *
                                            SC9->C9_LOTECTL						                         ,; //02
                                            SC6->C6_QTDVEN						                         ,; //03
                                            SC6->C6_UNSVEN						                         ,; //04
                                            _nPesoBruto                                             ,; //05
                                            SC6->C6_PRCVEN						                         ,; //06
                                            SC6->C6_VALOR						                         ,; //07
                                            _cDescItem							                         ,; //08
                                            SC9->C9_BLEST						                         ,; //09
                                            SC9->C9_BLCRED						                         ,; //10
                                            SB1->B1_I_QT3UM						                         ,; //11
                                            SB1->B1_I_3UM						                         ,; //12
                                            SB1->B1_UM							                         ,; //13
                                            SB1->B1_SEGUM						                         ,; //14 - SEGUNDA UNIDADE
                                            SB1->B1_TIPO						                            ,; //15 - TIPO PA
                                            SB1->( Recno() )					                         ,; //16
                                            _cNomRedCli                                             ,; //17 - Código/Nome
                                            LEFT(_cMunCli,20)                                       ,; //18 - Destino/Cidade
                                            Left(_cBairroCli,20)                                    ,; //19 - Bairro
                                            _cEstCli                                                ,; //20 - UF
                                            IF(Empty(SC9->C9_SEQENT),DAI->DAI_SEQUEN,SC9->C9_SEQENT),; //21 - Sequencia da Carga
                                            SC6->C6_PRODUTO+SC9->C9_LOTECTL+_cCliLoja               ,; //22 - Chave    *
                                            _cCliLoja                                               ,; //23 - Codigo do Cliente + Loja do Cliente
                                            _cGrupoPV                                               ,; //24 - Grupo PV *
                                            _cLocal                                                 ,; //25 - ARMAZEM  *
                                            SC6->C6_NUM                                             ,; //26 - LISTA DE PEDIDOS
                                            _cShelf})                                                  //27 - Shelf Life P
                       Else
                          _a3Produto[nPos][03] += SC6->C6_QTDVEN
                          _a3Produto[nPos][04] += SC6->C6_UNSVEN
                          _a3Produto[nPos][05] += _nPesoBruto
                          _a3Produto[nPos][07] += SC6->C6_VALOR
                          If !SC6->C6_NUM $ _a3Produto[nPos][26]
                               _a3Produto[nPos][26] += " / "+SC6->C6_NUM
                          EndIf
                       EndIf

                    EndIf

                    // MV_PAR03 == 1  .OR. MV_PAR03 == 2// Agrupamento padrão
                    If ( nPos := Ascan( _a1Produto , { |x| x[1]+x[2]+x[17] == SC6->C6_PRODUTO + SC9->C9_LOTECTL + _cGrupoPV } ) ) == 0
                       If !totvs.framework.environment.type.get() == '1'//1-Produção
                          _cDescItem:=LEFT(_cGrupoPV+"-"+_cDesGrFa+"-"+_cDesFami+"-"+_cDescItem,70)
                       EndIf

                       AADD(_a1Produto,  {  SC6->C6_PRODUTO                ,; //01 - Agrupamento 1 *
                                            SC9->C9_LOTECTL                ,; //02 - Agrupamento 2 *
                                            SC6->C6_QTDVEN	               ,; //03
                                            SC6->C6_UNSVEN	               ,; //04
                                            _nPesoBruto                    ,; //05
                                            SC6->C6_PRCVEN	               ,; //06
                                            SC6->C6_VALOR	               ,; //07
                                            _cDescItem		               ,; //08 - ORDENAÇÃO 4
                                            SC9->C9_BLEST	               ,; //09
                                            SC9->C9_BLCRED	               ,; //10
                                            SB1->B1_I_QT3UM	               ,; //11
                                            SB1->B1_I_3UM	               ,; //12
                                            SB1->B1_UM		               ,; //13
                                            SB1->B1_SEGUM	               ,; //14 - SEGUNDA UNIDADE
                                            SB1->B1_TIPO                   ,; //15 - TIPO PA
                                            SB1->( Recno() )               ,; //16
                                            _cGrupoPV                      ,; //17 - Agrupamento 3 *            ORDENAÇÃO 1
                                            _cLocal                        ,; //18 - Armazem *
                                            _cDesGrFa                      ,; //19 - Descrição Grupo de Família ORDENAÇÃO 2
                                            _cDesFami                      }) //20 - Descrição Família          ORDENAÇÃO 3
                    Else
                          _a1Produto[nPos][3] += SC6->C6_QTDVEN
                          _a1Produto[nPos][4] += SC6->C6_UNSVEN
                          _a1Produto[nPos][5] += _nPesoBruto
                          _a1Produto[nPos][7] += SC6->C6_VALOR
                    EndIf


                SC6->( DBSkip() )
                Enddo

            EndIf

            If MV_PAR03 == 3 .OR. MV_PAR03 == 4// Agrupamento utilizado apenas na emissão do relatório Ordem de Carga por Ponto de Entrega.
               _aProduto := ACLONE(_a3Produto)
            Else//MV_PAR03 == 1 .OR. MV_PAR03 == 2
               _aProduto := ACLONE(_a1Produto)
            EndIf

            //Utiliza a Funcao condicao para cada pedido que compoe a ordem de carga, para que seja efetua o calculo das parcelas a serem geradas para o pedido
            //de venda corrente para depois efetuar o somatorio geral dos valores a prazo e a vista - Fabiano Dias 04/08/10, isto somente para a filial de Manaus
            If cFilAnt == '91' .And. _nVlrPed > 0

                _nCont++   // 07/02/13 - Talita - Incluido o contador para verificar se tem pedido com financeiro
                _aParcelas := Condicao( _nVlrPed , _cConPgt ,, _dEmsPed )
                _aParcelas := ROMS004FMT( _aParcelas , _dEmsPed , _cConPgt )
                //Posicoes do array Parcela
                //1 - Vencimento da parcela
                //2 - Valor da parcela
                //3 - Emissao do pedido de venda
                //4 - Condicao de Pagamento do Pedido de venda
                aAdd( _aParcGer , _aParcelas )

            EndIf

           DAI->( DBSkip() )
        EndDo

    EndIf

 EndIf

 //====================================================================================================
 //Tratamento de acerto de SEQUENCIA DE ENTREGA:
 _aCliente:=ASort(_aCliente,,,{|x,y| x[2] < y[2] })//Indexa os clientes pela menos sequenvia de cada um

 FOR _nPosCli := 1 TO Len(_aCliente)
    _aCliente[_nPosCli,2]:=StrZero(_nPosCli,3)//Renumera as sequencias de entregas para 001,002,003...
 NEXT _nPosCli

 FOR _nPosRes := 1 TO Len(_a3Produto)
     If (_nPosCli:=ASCAN(_aCliente,{|C| C[1] == _a3Produto[_nPosRes,23] })  ) # 0
        _a3Produto[_nPosRes,21]:=_aCliente[_nPosCli,2]//+"-"+_a3Produto[_nPosRes,21]//Acerta na aResumo a nova sequencia dos Clientes
     EndIf
 NEXT _nPosRes
 //Tratamento de acertode SEQUENCIA DE ENTREGA:
 //====================================================================================================

 ROMS004Sub(_nColIni,_oPrint,_nLinha,_oFont08,1,.F.)

 ROMS004IQ1(MV_PAR03,If(MV_PAR03==3 .OR. MV_PAR03 == 4,_a3Produto,_a1Produto),_nColIni,_oPrint,@_nLinha,_oFont08,_nLinMax,_oFontIT)//AWF - 05/09/2016

 _nLinha += 030
 _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )

 If _nLinha >= _nLinMax - 100

    _oPrint:EndPage()
    _oPrint:StartPage()

    ROMS004Cab( @_oPrint , @_nLinha )

    _nLinha += 040

 EndIf

 _nLinha += 040

 _oFonTotal:=_oFont1Cour//_oFontIT/////////// TROCA FONTE

 _oPrint:Say( _nLinha , _nColIni	, 'Total Geral'											, _oFonTotal ) //Código do Produto
 _oPrint:Say( _nLinha , _nCol003	, Transform( _nTotQtd, "@E 999,999,999.99"	) +'      '	, _oFonTotal ,,,, 1 ) //Quantidade na 1ª UM
 _oPrint:Say( _nLinha , _nCol004	, Transform( _nTotQtd2,"@E 999,999,999.99"	) +'      '	, _oFonTotal ,,,, 1 ) //Quantidade na 2ª UM

 If MV_PAR03 == 1
    _oPrint:Say(_nLinha,_nCol005,Transform( _nTotQtd3, "@E 999,999,999.99"	) +'      '	, _oFonTotal ,,,, 1 ) //Total da Carga
 EndIf

 _oPrint:Say( _nLinha , _nCol006,Transform( _nTotPeso, "@E 999,999,999.99"	)			, _oFonTotal ,,,, 1 ) //Peso da Carga

 _nLinha += 030
 _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )

 If _nLinha >= _nLinMax - 100
     _oPrint:EndPage()
     _oPrint:StartPage()
     ROMS004Cab( @_oPrint , @_nLinha )
 EndIf

 _nLinha += 050

 _oFontIT:=_oFontCour/////////// TROCA FONTE

 ROMS004Sub(_nColIni,_oPrint,_nLinha,_oFont08,2,.F.)//Coloca os valores das colunas aqui na funcao

  For _nI := 1 to Len(_aResumo)

    //Impressao do cabecalho do relatorio
    _nLinha += 040

    If _nLinha >= _nLinMax

        _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )

        _oPrint:EndPage()
        _oPrint:StartPage()

        ROMS004Cab( @_oPrint , @_nLinha )

        _nLinha += 060

        ROMS004Sub(_nColIni,_oPrint,_nLinha,_oFont08,2,.F.)

        _nLinha += 060

    EndIf

    _oPrint:Say( _nLinha , _nCol003 , _aResumo[_nI][01], _oFontIT )         //'N.Fiscal'
    _oPrint:Say( _nLinha  ,_nCol004 , _aResumo[_nI][02], _oFontIT )         //'Cnpj'
    _oPrint:Say( _nLinha , _nCol005 , _aResumo[_nI][03], _oFontIT )         //'Nome
    _oPrint:Say( _nLinha , _nCol006	, _aResumo[_nI][04], _oFontIT )         //'Destino'
    _oPrint:Say( _nLinha , _nCol007 , _aResumo[_nI][05], _oFontIT )         //'UF'
    _oPrint:Say( _nLinha , _nCol008 , _aResumo[_nI][06], _oFontIT )         //'PV Carr'
    _oPrint:Say( _nLinha , _nCol009 , _aResumo[_nI][10], _oFontIT )         //'PV Fatu'
    _oPrint:Say( _nLinha , _nCol010 , _aResumo[_nI][07], _oFontIT )         //'Tipo de carga'
    _oPrint:Say( _nLinha , _nCol011 , _aResumo[_nI][11], _oFontIT )         //'Aramzem
    _oPrint:Say( _nLinha , _nCol012 , _aResumo[_nI][12], _oFontIT )         //'Valor Total //_oFont07

 Next _nI

 _nLinha += 030
 _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )

 If _nLinha >= _nLinMax - 100

     _oPrint:EndPage()
     _oPrint:StartPage()

     ROMS004Cab( @_oPrint , @_nLinha )

     _nLinha += 040

 EndIf

 _nLinha += 040

 _nPonEnt := Len(_aCliente)

 _oPrint:Say( _nLinha , _nColIni , 'Pontos de entrega: '+ cValToChar(_nPonEnt) + "                           " + _cMsgObs, _oFont08 )
 If Empty(_cMsgObs)
    _oPrint:Say( _nLinha , _nCol005 ,"TR-Redespacho / OP-Operador Logistico / CL-Cliente / FO-Fornecedor" , _oFont08 )
 EndIf
 _nLinha += 030

 _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )

 _cMsg2Obs:=Alltrim(StrTran(DAK->DAK_I_OBS,Char(13)+Char(10)," ") )

 If !Empty(_cMsg2Obs)

    _nLinha += 040
    _oFontObs:=TFont():New( "Arial" ,, 12 ,, .F.  )

    If _nLinha >= _nLinMax - 200

       _oPrint:EndPage()
       _oPrint:StartPage()
       ROMS004Cab( @_oPrint , @_nLinha )
       _nLinha += 010

    EndIf

    _cMsg2Obs:='Observações: '+ Alltrim(_cMsg2Obs)

    _nTam:=180
    FOR _nI := 1 TO MLCOUNT(_cMsg2Obs, _nTam )
        _oPrint:Say( _nLinha , _nColIni , MEMOLINE(_cMsg2Obs, _nTam ,_nI), _oFontObs )
        _nLinha += 050
    NEXT _nI

    _nLinha -= 020
    _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )

 EndIf

 //SE MV_PAR03 = 1 e 2 e 4  NÃO IMPRIMI ESSE RESUMO POR PRODUTO
 If (MV_PAR03 = 3 .AND. _nPonEnt > 1 ) //No tipo 3 bate os resumo Por Pallet tb Abaixo mas só tiver mais de um ponto de entrega
    _lResumoporProduto:=.T.
    If _nLinha >= _nLinMax - 200

          _oPrint:EndPage()
       _oPrint:StartPage()
       ROMS004Cab( @_oPrint , @_nLinha )

    EndIf

    _nLinha += 040
    _oPrint:Say( _nLinha , _nColIni, "Resumo por Produto", _oFont1Cour )

    _nLinha += 030
    _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )

    _nLinha += 040
    ROMS004Sub(_nColIni,_oPrint,_nLinha,_oFont08,1,.F.)//"RESUMO POR PRODUTO

    _nLinha += 030
    ROMS004IQ1(2,_a1Produto,_nColIni,_oPrint,@_nLinha,_oFont08,_nLinMax,_oFontIT)//AWF - 05/09/2016

    _nLinha += 030
    _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )
    _lResumoporProduto:=.F.
 EndIf

 If _nLinha >= _nLinMax - 300//200

     _oPrint:EndPage()
     _oPrint:StartPage()

     ROMS004Cab( @_oPrint , @_nLinha )

 EndIf

 _nLinha += 040

 //===============================================================================================
 // Imprime os quadros do rodapé da ordem de carga
 //===============================================================================================
 _oPrint:Say( _nLinha , _nColIni		, 'Resumo Financeiro:'        , _oFont08 )
 _oPrint:Say( _nLinha , _nColIni + 0520	, 'Declaração de Recebimento:', _oFont08 )
 _oPrint:Say( _nLinha , _nColIni + 1520	, 'Conferência:'              , _oFont08 )
 _oPrint:Say( _nLinha , _nColIni + 1780	, _cObsCarga                  , _oFont08 )

 nSoma   :=020
 nTira   :=050
 _nLF    :=150+75+75
 _nLinha +=025
 _oFontIT:=_oFont12

 _oPrint:Line( _nLinha		, _nColIni			, _nLinha		, _nColIni + 500	)//Linha inicial quadrado 1
 _oPrint:Line( _nLinha +_nLF , _nColIni			, _nLinha +_nLF	, _nColIni + 500	)//Linha final   quadrado 1

 _oPrint:Line( _nLinha		, _nColIni			, _nLinha +_nLF	, _nColIni			)//Coluna 1 quadrado
 _oPrint:Line( _nLinha		, _nColIni + 500	, _nLinha +_nLF	, _nColIni + 500	)//Coluna 1 quadrado

 _oPrint:Line( _nLinha		, _nColIni + 0520	, _nLinha		, _nColIni + 1500	)//Linha inicial quadrado 2
 _oPrint:Line( _nLinha +_nLF , _nColIni + 0520	, _nLinha +_nLF	, _nColIni + 1500	)//Linha final   quadrado 2

 _oPrint:Line( _nLinha		, _nColIni + 0520	, _nLinha +_nLF	, _nColIni + 0520	)//Coluna 2 quadrado
 _oPrint:Line( _nLinha		, _nColIni + 1500	, _nLinha +_nLF	, _nColIni + 1500	)//Coluna 2 quadrado

 _oPrint:Say( _nLinha + 015 + nSoma	, _nColIni + 0530	, 'Ao assinar esse documento afirmo ter acompanhado', _oFontIT )
 _oPrint:Say( _nLinha + 055 + nSoma	, _nColIni + 0530	, 'o processo de carregamento e confirmo ter'	    , _oFontIT )
 _oPrint:Say( _nLinha + 095 + nSoma	, _nColIni + 0530	, 'recebido as mercadorias em perfeito estado e na' , _oFontIT )
 _oPrint:Say( _nLinha + 135 + nSoma	, _nColIni + 0530	, 'quantidade correta conforme Nota Fiscal.'	    , _oFontIT )

 _oPrint:Line( _nLinha		, _nColIni + 1520	, _nLinha		, _nColMax			)// LINHA INICIAL QUADRADO 3
 _oPrint:Line( _nLinha + 075 , _nColIni + 1520	, _nLinha + 075	, _nColMax			)// LINHA MEIO 1  QUADRADO 3
 _oPrint:Line( _nLinha + 150 , _nColIni + 1520	, _nLinha + 150	, _nColMax			)// LINHA MEIO 2  QUADRADO 3
 _oPrint:Line( _nLinha + 225 , _nColIni + 1520	, _nLinha + 225	, _nColMax			)// LINHA MEIO 3  QUADRADO 3
 _oPrint:Line( _nLinha +_nLF , _nColIni + 1520	, _nLinha +_nLF	, _nColMax			)// LINHA FINAL   QUADRADO 3

 _oPrint:Line( _nLinha		, _nColIni + 1520	, _nLinha +_nLF	, _nColIni + 1520	)// COLUNA INICIAL QUADRADO 3
 _oPrint:Line( _nLinha		, _nColMax			, _nLinha +_nLF	, _nColMax			)// COLUNA FINAL   QUADRADO 3

 _oPrint:Line( _nLinha		, _nColIni + 1850 - nTira	, _nLinha + 075	, _nColIni + 1850 - nTira	) // COLUNA 1 MEIO EM CIMA QUADRADO 3
 _oPrint:Line( _nLinha		, _nColIni + 2180 - nTira	, _nLinha + 075	, _nColIni + 2180 - nTira	) // COLUNA 2 MEIO EM CIMA QUADRADO 3
 _oPrint:Line( _nLinha		, _nColIni + 2700 - nTira	, _nLinha + 075	, _nColIni + 2700 - nTira	) // COLUNA 3 MEIO EM CIMA QUADRADO 3
 _oPrint:Line( _nLinha + 075	, _nColIni + 2420 - nTira	, _nLinha +_nLF	, _nColIni + 2420 - nTira	) // COLUNA   MEIO EMBAIXO QUADRADO 3

 _oPrint:Say( _nLinha + 010 + nSoma	, _nColIni + 1680 - nTira - nTira	, 'CPF MOTORISTA:'    , _oFontCN	,,,, 2	)
 _oPrint:Say( _nLinha + 045 + nSoma	, _nColIni + 1680 - nTira - nTira - nTira, _cCGCMot		  , _oFontIT	,,,, 2	)

 _oPrint:Say( _nLinha + 010 + nSoma	, _nColIni + 2010 - nTira - nTira	, 'RG MOTORISTA:'     , _oFontCN	,,,, 2	)
 _oPrint:Say( _nLinha + 045 + nSoma	, _nColIni + 2010 - nTira - nTira - nTira, _cRGMot		  , _oFontIT	,,,, 2	)

 _oPrint:Say( _nLinha + 010 + nSoma	, _nColIni + 2300 - nTira			, 'ASSINATURA MOTORISTA:'  		, _oFontCN			)
 _oPrint:Say( _nLinha + 010 + nSoma	, _nColIni + 2850 - nTira - nTira	, 'DATA E HORA DA LIBERAÇÃO:'	, _oFontCN			)
 _oPrint:Say( _nLinha + 040 + nSoma	, _nColIni + 2770 - nTira - nTira	, '_____/_____/__________        ______ : ______'	)

 _oPrint:Say( _nLinha + 085 + nSoma	, _nColIni + 1550	        , 'IDENTIFICAÇÂO E ASSINATURA DO CONFERENTE:'	, _oFontCN	)
 _oPrint:Say( _nLinha + 085 + nSoma	, _nColIni + 2450 - nTira	, 'IDENTIFICAÇÂO E ASSINATURA DO(A) MESÁRIO(A):', _oFontCN	)

 _oPrint:Say( _nLinha + 160 + nSoma	, _nColIni + 1550	        , 'ASSINATURA ESTIVADOR 1:'	, _oFontCN	)
 _oPrint:Say( _nLinha + 160 + nSoma	, _nColIni + 2450 - nTira   , 'ASSINATURA ESTIVADOR 2:'	, _oFontCN	)

 _oPrint:Say( _nLinha + 235 + nSoma	, _nColIni + 1550	        , 'HORA INICIAL CARREGAMENTO:', _oFontCN	)
 _oPrint:Say( _nLinha + 235 + nSoma	, _nColIni + 2450 - nTira   , 'HORA FINAL CARREGAMENTO:'  , _oFontCN	)

 //===============================================================================================
 // Reseta variáveis para não "acumular saldo" nos resumos
 //===============================================================================================
 _nAvista	:= 0
 _nAprazo	:= 0

 //===============================================================================================
 // Se for Filial de Manaus, imprime os valores de preco a vista e a prazo
 //===============================================================================================
 If cFilAnt == '91' .AND. !Empty(_aParcGer)

    For x := 1 To Len(_aParcGer)

        For y := 1 to Len(_aParcGer[x])

            //===============================================================================================
            // Se a condicao de pagamento for igual 001 considera pagamento a vista
            //===============================================================================================
            If _aParcGer[x][y][4] == '001'

                _nAvista += _aParcGer[x][y][2]

            Else

                //Pagamento a Vista
                If _aParcGer[x][y][1] == _aParcGer[x][y][3]

                    _nAvista += _aParcGer[x][y][2]

                Else

                    _nAprazo += _aParcGer[x][y][2]

                EndIf

            EndIf

        Next y

    Next x

    _oPrint:Say( _nLinha + 040 , _nColIni + 020	, 'À vista: '+Transform( _nAvista , "@E 999,999,999.99" ), _oFont2Cour)

    _oPrint:Say( _nLinha + 080 , _nColIni + 020	, 'À prazo: '+Transform( _nAprazo , "@E 999,999,999.99" ), _oFont2Cour)

    _oPrint:Say( _nLinha + 120 , _nColIni + 020	, 'Total..: '+Transform(_nAvista+_nAprazo,"@E 999,999,999.99"),_oFont2Cour)

 EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS004CNV
Autor-------------: Alexandre Villar
Data da Criacao---: 03/12/2014
Descrição---------: Função para conversão entre unidades de medida
Parametros--------: _nQtdAux As Numeric , _nUMOri As Numeric , _nUMDes  As Numeric 
Retorno-----------: _nRet As Numeric
===============================================================================================================================
*/
Static Function ROMS004CNV( _nQtdAux As Numeric , _nUMOri As Numeric , _nUMDes As Numeric ) As Numeric
 Local _nRet := 0 As Numeric

 Do Case

    Case _nUMDes == 1

        //================================================================================
        // Conversão da Segunda UM para a Primeira
        //================================================================================
        If _nUMOri == 2

            If SB1->B1_TIPCONV == 'D'
                _nRet := _nQtdAux * SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nQtdAux / SB1->B1_CONV
            EndIf

        //================================================================================
        // Conversão da Terceira UM para a Primeira
        //================================================================================
        ElseIf _nUMOri == 3

            _nRet := _nQtdAux * SB1->B1_I_QT3UM

        EndIf

    Case _nUMDes == 2

        //================================================================================
        // Conversão da Primeira UM para a Segunda
        //================================================================================
        If _nUMOri == 1

            If SB1->B1_TIPCONV == 'D'
                _nRet := _nQtdAux / SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nQtdAux * SB1->B1_CONV
            EndIf

        //================================================================================
        // Conversão da Terceira UM para a Segunda
        //================================================================================
        ElseIf _nUMOri == 3

            _Ret := _nQtdAux * SB1->B1_I_QT3UM

            If SB1->B1_TIPCONV == 'D'
                _nRet := _nRet / SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nRet * SB1->B1_CONV
            EndIf

        EndIf

    Case _nUMDes == 3

        //================================================================================
        // Conversão da PRIMEIRA UM PARA A TERCEIRA
        //================================================================================
        If _nUMOri == 1

            _nRet := _nQtdAux / SB1->B1_I_QT3UM

        //================================================================================
        // Conversão da SEGUNDA UM PARA A TERCEIRA
        //================================================================================
        ElseIf _nUMOri == 2

            If SB1->B1_CONV > 0
               If SB1->B1_TIPCONV == 'D'
                     _nRet := _nQtdAux * SB1->B1_CONV
               ElseIf SB1->B1_TIPCONV == 'M'
                     _nRet := _nQtdAux / SB1->B1_CONV
               EndIf
            Else//SÓ PARA O QUEIJO
               _nRet := _nQtdAux
            EndIf

            _nRet := _nRet / SB1->B1_I_QT3UM

        EndIf

 EndCase

Return( _nRet )

/*
===============================================================================================================================
Programa----------: ROMS004FMT
Autor-------------: Alexandre Villar
Data da Criacao---: 03/12/2014
Descrição---------: Função que faz o processamento dos dados para retorno em Array
Parametros--------: _aParcelas As Array,_cEmisPed As Char,_cCondPgt As Char
Retorno-----------: _aAux As Array
===============================================================================================================================
*/

Static Function ROMS004FMT(_aParcelas As Array,_cEmisPed As Char,_cCondPgt As Char) As Array
 Local _aAux:= {} As Array
 Local x := 0 As Numeric
 For x:=1 to Len(_aParcelas)
     aAdd( _aAux,{_aParcelas[x,1],_aParcelas[x,2],_cEmisPed,_cCondPgt} )
 Next x
Return _aAux
/*
===============================================================================================================================
Programa----------: ROMS004Sub()
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2014
Descrição---------: Imprimie os cabecalho  das colulas dos pedidos
Parametros--------: _nColIni As Numeric,_oPrint As Object,_nLinha As Numeric,_oFont08 As Object,nCab As Numeric,lIniColunas As Logical
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function ROMS004Sub(_nColIni As Numeric,_oPrint As Object,_nLinha As Numeric,_oFont08 As Object,nCab As Numeric,lIniColunas As Logical) As Logical
 Local _nDif4:=0 As Numeric
 If nCab = 1

     If MV_PAR03 == 4 .AND. !_lResumoporProduto
        _nDif4:=30//POR CAUSA DO ARMAZEM / Local
     EndIf
     _nCol002:= _nColIni + 0300-_nDif4//'Descrição do Produto'
     _nCol003:= _nCol002 + 1445+_nDif4//'Qtde. 1ª UM'
     _nCol004:= _nCol003 + 0325//'Qtde. 2ª UM'
     If MV_PAR03 == 1
         _nCol005:= _nCol004 + 0350//'Qtde. 3ª UM'
     Else
         _nCol005:= _nCol004 + 0420//'Carga Total'
     EndIf
     _nCol006:= _nCol004 + 0750//'Peso'

     If lIniColunas
        Return .T.
     EndIf

     _oPrint:Say( _nLinha , _nColIni	, 'Produto'		   			, _oFont08 )
     If MV_PAR03 == 4 .AND. !_lResumoporProduto
        _oPrint:Say(_nLinha,_nCol002	, 'Amz Descrição do Produto', _oFont08 )
     Else
        _oPrint:Say(_nLinha,_nCol002	, 'Descrição do Produto'	, _oFont08 )
     EndIf
     _oPrint:Say( _nLinha , _nCol003+110, 'Qtde. 1ª UM'			, _oFont08 )
     _oPrint:Say( _nLinha , _nCol004+110, 'Qtde. 2ª UM'			, _oFont08 )
     If MV_PAR03 == 1
         _oPrint:Say( _nLinha , _nCol005+110, 'Qtde. 3ª UM'		, _oFont08 )
     Else
         _oPrint:Say( _nLinha , _nCol005	, 'Carga Total'			, _oFont08 )
     EndIf
     _oPrint:Say( _nLinha , _nCol006+150, 'Peso'			    	, _oFont08 )


 ElseIf nCab = 2

     If  _lAutoRel .OR. _oPrint:CPRINTER == "PDF"//_oPrint:CPRINTER == "PDF" quer dizer Exporta PDF via tela
         _nCol003:= _nColIni           //'N.Fiscal'
         _nCol004:= _nCol003 + 0240//'Cnpj'
         _nCol005:= _nCol004 + 0440//'Código - Nome'//290
         _nCol006:= _nCol005 + 0900//'Destino'
         _nCol007:= _nCol006 + 0470//'UF'
         _nCol008:= _nCol007 + 0070//'PV Carr'
         _nCol009:= _nCol008 + 0220//'PV Fatu'
         _nCol010:= _nCol009 + 0215//'Tipo de carga'
         _nCol011:= _nCol010 + 0250//'Amz
         _nCol012:= _nCol011 + 0100//'Valor total'
     ElseIf !_lAutoRel .AND. !(_oPrint:CPRINTER == "PDF")//_oPrint:CPRINTER == "PDF" quer dizer Exporta PDF via tela
         _nCol003:= _nColIni           //'N.Fiscal'
         _nCol004:= _nCol003 + 0240//'Cnpj'
         _nCol005:= _nCol004 + 0440//'Código - Nome'//290
         _nCol006:= _nCol005 + 0900//'Destino'
         _nCol007:= _nCol006 + 0470//'UF'
         _nCol008:= _nCol007 + 0070//'PV Carr'
         _nCol009:= _nCol008 + 0220//'PV Fatu'
         _nCol010:= _nCol009 + 0215//'Tipo de carga'
         _nCol011:= _nCol010 + 0250//'Amz
         _nCol012:= _nCol011 + 0100//'Valor total'
     EndIf

     _oPrint:Say( _nLinha , _nCol003, 'N.Fiscal'                , _oFont08 )
     _oPrint:Say( _nLinha , _nCol004, 'CNPJ'                    , _oFont08 )
     _oPrint:Say( _nLinha , _nCol005, 'Nome'                    , _oFont08 )
     _oPrint:Say( _nLinha , _nCol006, 'Destino'                 , _oFont08 )
     _oPrint:Say( _nLinha , _nCol007, 'UF'                      , _oFont08 )
     _oPrint:Say( _nLinha , _nCol008, 'PV Carregam'             , _oFont08 )
     _oPrint:Say( _nLinha , _nCol009, 'PV Faturam'              , _oFont08 )
     _oPrint:Say( _nLinha , _nCol010, 'Tipo de carga'           , _oFont08 )
     _oPrint:Say( _nLinha , _nCol011, 'Arm'                     , _oFont08 )
     _oPrint:Say( _nLinha , _nCol012, 'Valor'                   , _oFont08 )

 EndIf
Return .t.
/*
===============================================================================================================================
Programa----------: ROMS004NameFile()
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2014
Descrição---------: Gera o nome do arquivo com date() e time()
Parametros--------: cCarga - numero da carga que será usado como parte do nome do arquivo
Retorno-----------: cFilename
===============================================================================================================================
*/
Static Function ROMS004NameFile(cCarga) As Char
 Local cFilename:= "" As Char
 Local cAux     := "" As Char

 cFilename:="CARGA_"
 If !Empty(cCarga)
    cFilename+=Alltrim(cCarga)+"_"
    cFilename+="EMAIL_"
 Else
    cFilename+="TELA_"
 EndIf
 cFilename+=DToS( Date() ) + "_"

 cAux:=Time()
 cAux:=StrTran( cAux , ":" , "" )

 cFilename:=cFilename+cAux+".pdf"

Return cFilename

/*
===============================================================================================================================
Programa----------: ROMS004IQ1
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2014
Descrição---------: Imprimi a primeira parte do Relatorio
Parametros--------: nTipoRel  - Tipo do relatorio 1,2,3 ou 4
                    _aProduto - Array com os produtos a serem impressos
                    _nColIni  - Coluna inicial da impressão
                    _oPrint   - Objeto de impressão
                    _nLinha   - Linha inicial da impressão
                    _oFont08  - Fonte 08
                    _nLinMax  - Numero maximo de linhas por pagina
                    _oFontIT  - Fonte IT
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS004IQ1(nTipoRel As Numeric,_aProduto As Array,_nColIni As Numeric,_oPrint As Object,_nLinha As Numeric,_oFont08 As Object, _nLinMax As Numeric,_oFontIT As Object)
 Local _nQtdReg    := Len( _aProduto ) As Numeric
 Local _nI         := 0 As Numeric
 Local _aCfgOc     := {} As Array
 Local _oBrush     := TBrush():New( , RGB( 215 , 215 , 215 ) ) As Object
 Local _a3Totais   := {} As Array
 Local _lImpLinCt  := .T. As Logical
 Local _cCodNomeCli:= "" As Char

 If nTipoRel == 3  .OR. nTipoRel == 4 // Imprime dados do cliente na quebra do tipo:  MV_PAR03 = 3 E 4

    _aProduto:= ASort(_aProduto,,,{|x,y| x[21]+x[17]+x[24]+x[8] < y[21]+y[17]+y[24]+y[8] })//Seq Carga + Nome CLI + _Grupo PV + Descricao Item

    _cCodNomeCli := "" // Código e Nome do Cliente para quebra do relatório.
    For _nI := 1 To _nQtdReg
        If Alltrim(_cCodNomeCli) <> Alltrim(_aProduto[_nI][23]) //Codigo + Loja FAZ QUEBRA igual da impressao
           _cCodNomeCli := _aProduto[_nI][23]
           AADD( _a3Totais ,{_aProduto[_nI][21]+_aProduto[_nI][23] ,;//01 //Seq + (Codigo + Loja)
                             _aProduto[_nI][05] })//02 - Acumula peso
        Else
           _a3Totais[ Len(_a3Totais) ][2] += _aProduto[_nI][05] //02 - Acumula peso
        EndIf
   Next _nI

 Else//SE MV_PAR03 = 1 ou 2  ou (MV_PAR03 = 3 .AND. _nPonEnt > 1 ) //No MV_PAR03 =  3 bate os resumo Por Pallet tb Abaixo mas só tiver mais de um ponto de entrega

    If Len(_aProduto[1]) > 23 //  MV_PAR03 = 3
       _aProduto:= ASort(_aProduto,,,{|x,y| x[24]+x[8] < y[24]+y[8] })//Grupo PV + Descricao
    Else                      //  MV_PAR03 = 1 ou 2
       _aProduto:= ASort(_aProduto,,,{|x,y| x[17]+x[8] < y[17]+y[8] })//Grupo PV + Descricao
    EndIf
 EndIf

 If MV_PAR03 = 1 .OR. MV_PAR03 = 2                                                           // _cGrupoPV + _cDesGrFa + _cDesFami + _cDescItem
    _aProduto:= ASort(_aProduto,,,{|x,y| x[17]+x[19]+x[20]+x[08] < y[17]+y[19]+y[20]+y[08] })// Grupo PV + Descrição Grupo BI +  Descrição Grupo Família BI  + Descricao
 EndIf

 _cCodNomeCli:= "" // Código e Nome do Cliente para quebra do relatório.
 _nTotQtd	 := 0
 _nTotQtd2	 := 0
 _nTotQtd3	 := 0
 _nTotPeso	 := 0

 ROMS004Sub(_nColIni,_oPrint,_nLinha,_oFont08,1,.T.)//Inicia os valores das colunas pq é diferente do cab2

 For _nI := 1 To _nQtdReg


    SB1->( DBGoTo( _aProduto[_nI][16] ) )

    If nTipoRel== 1///******************************  MV_PAR03 =  1

        _nLinha += 040

        //====================================================================================================
        // Verifica necessidade de quebra de página
        //====================================================================================================
        If _nLinha >= _nLinMax

            _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )

            _oPrint:EndPage()
            _oPrint:StartPage()

            ROMS004Cab( @_oPrint , @_nLinha )

            ROMS004Sub(_nColIni,_oPrint,_nLinha,_oFont08,1,.F.)

            _nLinha += 060

        EndIf

        //====================================================================================================
        // Imprime linha separadora de data critica
        //====================================================================================================
        If _lImpLinCt
           If Len(_aProduto[_nI]) > 20
              If _aProduto[_nI,24] == "B"
                 //_nLinha += 060
                 _oPrint:Say( _nLinha , _nCol002	, "*************************************   Contém Data Crítica   *************************************" , _oFontIT )
                 _lImpLinCt := .F.
                 _nLinha += 060
              EndIf
           Else
              If _aProduto[_nI,17] == "B"
                 //_nLinha += 060
                 _oPrint:Say( _nLinha , _nCol002	, "*************************************   Contém Data Crítica   *************************************"  , _oFontIT )
                 _lImpLinCt := .F.
                 _nLinha += 060
              EndIf
           EndIf
        Else
           If Len(_aProduto[_nI]) > 20
              If _aProduto[_nI,24] == "A"
                 _lImpLinCt := .T.
              EndIf
           Else
              If _aProduto[_nI,17] == "A"
                 _lImpLinCt := .T.
              EndIf
           EndIf
        EndIf

        //====================================================================================================
        // Imprime linha pontilhada
        //====================================================================================================
        If _nI <= _nQtdReg
            If ( _nI % 2 ) == 0
                  _oPrint:FillRect( EVAL(_bCoordRect,_nLinha) , _oBrush )//{|L| { L-28 , _nColIni , L+2 , _nColMax }
            EndIf
        EndIf

        _aProduto[_nI][08]:=STRTRAN(_aProduto[_nI][08],"zz","")//Tira o zz na frente da Descrisão do item PALLET para ele ficar por ultimo na lista sempre

        _oPrint:Say( _nLinha , _nColIni	, _aProduto[_nI][01]   									, _oFontIT ) // Código do Produto
        _oPrint:Say( _nLinha , _nCol002	, PadR( _aProduto[_nI][8] , 80 )						, _oFontIT ) // Descrição do Produto //_cDescItem
        _oPrint:Say( _nLinha , _nCol003	, Transform( _aProduto[_nI][03] , "@E 999,999,999.99" )+'      '	, _oFontIT ,,,, 1 ) // Quantidade na 1ª UM
        _oPrint:Say( _nLinha , _nCol004	, Transform( _aProduto[_nI][04] , "@E 999,999,999.99" )+'      '	, _oFontIT ,,,, 1 ) // Quantidade na 2ª UM

        If !Empty(_aProduto[_nI][11]) //Tratamento para impressão da Quantidade na 3ª UM // SB1->B1_I_QT3UM

            If Alltrim(_aProduto[_nI][14]) == "PC" .And. Alltrim(_aProduto[_nI][15]) == "PA" //Tratamento para o QUEIJO
                                                                                     //B1_I_QT3UM
                _oPrint:Say( _nLinha , _nCol005 , Transform( ( _aProduto[_nI][04] / _aProduto[_nI][11] ) , "@E 999,999,999.99" ) +" "+ _aProduto[_nI][12]	, _oFontIT ,,,, 1 )
            Else                                                                    //B1_I_QT3UM
                _oPrint:Say( _nLinha , _nCol005 , Transform( ( _aProduto[_nI][03] / _aProduto[_nI][11] ) , "@E 999,999,999.99" ) +" "+ _aProduto[_nI][12]	, _oFontIT ,,,, 1 )
            EndIf

        EndIf

        _oPrint:Say( _nLinha , _nCol006	, Transform( _aProduto[_nI][05] , "@E 999,999,999.99" )	, _oFontIT ,,,, 1 ) // Peso da Carga

        _nTotQtd	+= _aProduto[_nI][03] // QTDE
        _nTotQtd2	+= _aProduto[_nI][04] // QTDE2

        If !Empty(_aProduto[_nI][11])

            If Alltrim( _aProduto[_nI][14] ) == "PC" .And. Alltrim( _aProduto[_nI][15] ) == "PA" //Tratamento foi para o queijo
                _nTotQtd3 += ( _aProduto[_nI][04] / _aProduto[_nI][11] ) //QTDE3
            Else
                _nTotQtd3 += ( _aProduto[_nI][03] / _aProduto[_nI][11] ) //QTDE3
            EndIf

        EndIf

        _nTotPeso += _aProduto[_nI][05] //PESO

    Else//******************************   MV_PAR03 == 2  / MV_PAR03== 3 / MV_PAR03== 4
        //------ Local anterior de impressão da mensagem de Data Crítica.
        // Dados para impressão da PRIMEIRA UNIDADE de Medida do Relatório
        If SB1->B1_I_QTOC1 == '1' .Or. Empty( SB1->B1_I_QTOC1 )
            aAdd( _aCfgOC , Transform( _aProduto[_nI][03]		  				, '@E 999,999,999.99' ) +' '+ PadR( SB1->B1_UM		, TamSX3( 'B1_UM' )[01]		) )
            _nTotQtd	 += _aProduto[_nI][3]	//QTDE
        ElseIf SB1->B1_I_QTOC1 == '2'
            aAdd( _aCfgOC , Transform( _aProduto[_nI][4] /*ROMS004CNV( _aProduto[_nI][03] , 1 , 2 )*/	, '@E 999,999,999.99' ) +' '+ PadR( SB1->B1_SEGUM	, TamSX3( 'B1_SEGUM' )[01]	) )
            _nTotQtd	 += _aProduto[_nI][4] //ROMS004CNV( _aProduto[_nI][03] , 1 , 2 )	//QTDE
        ElseIf SB1->B1_I_QTOC1 == '3'
            aAdd( _aCfgOC , Transform( ROMS004CNV( _aProduto[_nI][03] , 1 , 3 )	, '@E 999,999,999.99' ) +' '+ PadR( SB1->B1_I_3UM	, TamSX3( 'B1_I_3UM' )[01]	) )
            _nTotQtd	 += ROMS004CNV( _aProduto[_nI][03] , 1 , 3 )	//QTDE
        Else
            aAdd( _aCfgOC , '' )
        EndIf

        //================================================================================
        // Dados para impressão da SEGUNDA UNIDADE de Medida do Relatório
        //================================================================================
        If SB1->B1_I_QTOC2 == '1'
            aAdd( _aCfgOC , Transform( _aProduto[_nI][03]						, '@E 999,999,999.99' ) +' '+ SB1->B1_UM   )
            _nTotQtd2 += _aProduto[_nI][3] //QTDE2
        ElseIf SB1->B1_I_QTOC2 == '2' .Or. ( Empty( SB1->B1_I_QTOC1 ) .And. Empty( SB1->B1_I_QTOC2 ) )
            aAdd( _aCfgOC , Transform( _aProduto[_nI][4] /*ROMS004CNV( _aProduto[_nI][03] , 1 , 2 )*/	, '@E 999,999,999.99' ) +' '+ SB1->B1_SEGUM)
            _nTotQtd2 += _aProduto[_nI][4] //ROMS004CNV( _aProduto[_nI][03] , 1 , 2 ) //QTDE2
        ElseIf SB1->B1_I_QTOC2 == '3'
            aAdd( _aCfgOC , Transform( ROMS004CNV( _aProduto[_nI][03] , 1 , 3 )	, '@E 999,999,999.99' ) +' '+ SB1->B1_I_3UM)
            _nTotQtd2 += ROMS004CNV( _aProduto[_nI][03] , 1 , 3 ) //QTDE2
        Else
            aAdd( _aCfgOC , '' )
        EndIf

        _nQtPallet	:= 0
        _nQtSobra	:= 0
        _nQtNoPl	:= 0
        _cUMPal		:= ''

        //================================================================================
        // Cálculo da quantidade de Pallets
        //================================================================================
        If SB1->B1_I_UMPAL == '1'

            _nQtPallet	:= Int( _aProduto[_nI][03] / SB1->B1_I_CXPAL )

        ElseIf SB1->B1_I_UMPAL == '2'

            If Alltrim(_aProduto[_nI][14]) == "PC" .And. Alltrim(_aProduto[_nI][15]) == "PA" //Tratamento para o QUEIJO
               _nQtPallet	:= Int(  _aProduto[_nI][04]  / SB1->B1_I_CXPAL )
            Else
               _nQtPallet	:= Int( ROMS004CNV( _aProduto[_nI][03] , 1 , 2 ) / SB1->B1_I_CXPAL )
            EndIf

        ElseIf SB1->B1_I_UMPAL == '3'

            _nQtPallet	:= Int( ROMS004CNV( _aProduto[_nI][03] , 1 , 3 ) / SB1->B1_I_CXPAL )

        Else

            _nQtPallet	:= 0
            _nQtSobra	:= 0
            _cUMPal		:= ''

        EndIf

        _nQtNoPl := ( _nQtPallet * SB1->B1_I_CXPAL )

        //================================================================================
        // Dados para impressão da sobra com relação aos Pallets completos
        //================================================================================
        If SB1->B1_I_QTOC3 == '1'

            If SB1->B1_I_UMPAL == '2'
                _nQtNoPl := ROMS004CNV( _nQtNoPl , 2 , 1 )
            ElseIf SB1->B1_I_UMPAL == '3'
                _nQtNoPl := ROMS004CNV( _nQtNoPl , 3 , 1 )
            EndIf

            _nQtSobra	:= _aProduto[_nI][03] - _nQtNoPl
            _cUMPal		:= PadR( SB1->B1_UM , TamSX3( 'B1_UM' )[01] )

        ElseIf SB1->B1_I_QTOC3 == '2'

            If SB1->B1_I_UMPAL == '1'
                _nQtNoPl := ROMS004CNV( _nQtNoPl , 1 , 2 )
            ElseIf SB1->B1_I_UMPAL == '3'
                _nQtNoPl := ROMS004CNV( _nQtNoPl , 3 , 2 )
            EndIf

            _nQtSobra	:= ROMS004CNV( _aProduto[_nI][03] , 1 , 2 ) - _nQtNoPl
            _cUMPal		:= PadR( SB1->B1_SEGUM , TamSX3( 'B1_SEGUM' )[01] )

        ElseIf SB1->B1_I_QTOC3 == '3'

            If SB1->B1_I_UMPAL == '1'
               _nQtNoPl := ROMS004CNV( _nQtNoPl , 1 , 3 )
               _nQtSobra:= ROMS004CNV( _aProduto[_nI][03] , 1 , 3 ) - _nQtNoPl
            ElseIf SB1->B1_I_UMPAL == '2'
               _nQtNoPl := ROMS004CNV( _nQtNoPl , 2 , 3 )//CONVERTE PARA CAIXAS
               _nQtSobra:= ROMS004CNV( _aProduto[_nI][04] , 2 , 3 ) - _nQtNoPl
            EndIf

            _cUMPal		:= PadR( SB1->B1_I_3UM , TamSX3( 'B1_I_3UM' )[01] )

        Else

            _nQtPallet	:= 0
            _nQtSobra	:= 0
            _cUMPal		:= ''

        EndIf

        _cInfPal := ''

        If !Empty( _cUMPal )

            If _nQtPallet > 0
                _cInfPal := cValToChar( _nQtPallet ) + ' Pallet' + IIf( _nQtPallet > 1 , 's' , '' ) + IIf( _nQtSobra > 0 , ' + ' , '' )
            EndIf

            If _nQtSobra > 0
                _cInfPal += cValToChar( _nQtSobra ) +' '+ _cUMPal
            EndIf

        EndIf

        aAdd( _aCfgOC , _cInfPal )

        _nLinha += 040

        //====================================================================================================
        // Verifica necessidade de quebra de página
        //====================================================================================================
        If _nLinha >= _nLinMax

            _oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )

            _oPrint:EndPage()
            _oPrint:StartPage()

            ROMS004Cab( @_oPrint , @_nLinha )

            ROMS004Sub(_nColIni,_oPrint,_nLinha,_oFont08,1,.F.)

            _nLinha += 060

        EndIf

        If nTipoRel == 3 .OR. nTipoRel == 4//Imprime dados do cliente na quebra do tipo 3 e 4  MV_PAR03 =  3 OU 4
           If Alltrim(_cCodNomeCli) <> Alltrim(_aProduto[_nI][23])
              _cCodNomeCli := _aProduto[_nI][23]
              _nTotPonto:=0
                 If ( nPos := Ascan( _a3Totais , { |x| x[1] == _aProduto[_nI][21]+_aProduto[_nI][23] } ) ) # 0
                 _nTotPonto:=_a3Totais[nPos][2]
              EndIf

              _nLinha += 30//020
              _oPrint:Say( _nLinha , _nColIni, _aProduto[_nI,21]+" - "+Alltrim(_aProduto[_nI][17]) +" - "+Alltrim(_aProduto[_nI][18])+" / "+Alltrim(_aProduto[_nI][20])+" - Bairro: "+ Alltrim(_aProduto[_nI][19])+" - Tot.: Kg "+Alltrim(Transform(_nTotPonto,"@E 9,999,999,999.99"))+" - PV(s): "+_aProduto[_nI,26]+ Iif(Empty(Alltrim(_aProduto[_nI,27])),""," - SHELF LIFE P "+_aProduto[_nI,27]), _oFont1Cour  )
              _nLinha += 50//040

           EndIf

        EndIf

        //====================================================================================================
        // Imprime linha pontilhada
        //====================================================================================================
        If _nI <= _nQtdReg
            If ( _nI % 2 ) == 0
                  _oPrint:fillRect( EVAL(_bCoordRect,_nLinha) , _oBrush )
            EndIf
        EndIf

        //====================================================================================================
        // Imprime linha separadora de data critica
        //====================================================================================================
        If _lImpLinCt
           If Len(_aProduto[_nI]) > 20
              If _aProduto[_nI,24] == "B"
                 //_nLinha += 060
                 _oPrint:Say( _nLinha , _nCol002	,  "*************************************   Contém Data Crítica   *************************************" , _oFontIT )
                 _lImpLinCt := .F.
                 _nLinha += 060
              EndIf
           Else
              If _aProduto[_nI,17] == "B"
                 //_nLinha += 060
                 _oPrint:Say( _nLinha , _nCol002	, "*************************************   Contém Data Crítica   *************************************" , _oFontIT )
                 _lImpLinCt := .F.
                 _nLinha += 060
              EndIf
           EndIf
        Else
           If Len(_aProduto[_nI]) > 20
              If _aProduto[_nI,24] == "A"
                 _lImpLinCt := .T.
              EndIf
           Else
              If _aProduto[_nI,17] == "A"
                 _lImpLinCt := .T.
              EndIf
           EndIf
        EndIf

        _aProduto[_nI][08]:=STRTRAN(_aProduto[_nI][08],"zz","")//Tira o zz na frente da Descrisão do item PALLET para ele ficar por ultimo na lista sempre
        _cDescricao:=PadR( _aProduto[_nI][08] , 80 )
        If MV_PAR03 == 4
           If nTipoRel = 4 .AND. Len(_aProduto[_nI]) > 24  //POSICAO DO RMAZEM
              _cDescricao:=_aProduto[_nI][25]+" "+PadR( _aProduto[_nI][08] , 80 ) // desativdo por ENQUANTO
           //ElseIf nTipoRel = 2 .AND. Len(_aProduto[_nI]) > 17 .AND. _lResumoporProduto//POSICAO DO RMAZEM
           //   _cDescricao:=_aProduto[_nI][18]+" "+PadR( _aProduto[_nI][08] , 80 )
           EndIf
        EndIf

        _oPrint:Say( _nLinha , _nColIni, Alltrim( _aProduto[_nI][01] )		                , _oFontIT ) //Código do Produto
        _oPrint:Say( _nLinha , _nCol002, _cDescricao 						                , _oFontIT ) //Descrição do Produto
        _oPrint:Say( _nLinha , _nCol003-40, _aCfgOc[01]					                    , _oFontIT )//,,,, 1 ) //Quantidade na 1ª UM
        If !Empty(_aCfgOc[02]) .And. Alltrim(_aCfgOc[02]) <> '0,00'
           _oPrint:Say( _nLinha , _nCol004	, _aCfgOc[02]									, _oFontIT )//,,,, 1 ) //Quantidade na 2ª UM
        EndIf
        If !Empty(_aCfgOc[03])
           _oPrint:Say( _nLinha , _nCol005	, _aCfgOc[03]		  							, _oFontIT )//,,,, 2 ) //Total da Carga
        EndIf
        _oPrint:Say( _nLinha , _nCol006,Transform(_aProduto[_nI][05],"@E 999,999,999.99" )	, _oFontIT )//,,,, 1 ) //Peso da Carga

        _nTotPeso += _aProduto[_nI][05]//PESO

    EndIf

    _aCfgOc := {}

 Next _nI

RETURN 

/*
===============================================================================================================================
Programa----------: ROMS004Dtc
Autor-------------: Julio de Paula Paz
Data da Criacao---: 06/03/2023
Descrição---------: Retorna se existe data critica para algum pedido de vendas contido na carga.
Parametros--------: _cFilCarga = Filial da carga.
                    _cNrCarga  = Numero da carga.
Retorno-----------: _cRet
===============================================================================================================================
*/
Static Function ROMS004Dtc(_cFilCarga, _cNrCarga) As Char
 Local _cRet := " " As Char

 SC5->(DbSetOrder(1))
 DAI->(DbSetOrder(1)) // DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
 DAI->(MsSeek(_cFilCarga + _cNrCarga))
 While ! DAI->(Eof()) .And. DAI->DAI_FILIAL + DAI->DAI_COD == _cFilCarga + _cNrCarga
    SC5->(MsSeek(DAI->DAI_FILIAL + DAI->DAI_PEDIDO))

    If SC5->C5_I_OPER == "24"
       _cRet := "** Contém Data Crítica **"
       Exit
    EndIf

    DAI->(DBSkip())
 EndDo

Return _cRet
/*
===============================================================================================================================
Programa--------: MostraCalls()
Autor-----------: Alex Wallauer
Data da Criacao-: 22/11/2023
Descrição-------: Mostra os caminho ate o momento
Parametros------: Nenhum
Retorno---------: cPilha
===============================================================================================================================
*/
User Function MostraCalls() As Char
 Local _bType:= {|x| Type(x)} As Block
 Local nConta:=0 As Numeric
 Local cPilha:="" As Char
 Local cPilhaS:="" As Char
 Local cProcName:="XX" As Char
 While !Empty(cProcName) .AND. nConta < 25
    cProcName:=PROCNAME(nConta)
    cPilha:=""
    If !Empty(cProcName) //.AND. !cProcName $ "ACTIVATE/FWMSGRUN/PROCESSA/__EXECUTE/FWPREEXECUTE/SIGAIXB"///SIGAADV
       aTipo:={};   aArquivo:={};   aLinha:={};   aData:={};   aHora:={}
       aRet :=GetFuncArray( PROCNAME(nConta),aTipo,aArquivo,aLinha,aData,aHora)
       cPilha+=STRTRAN(PROCNAME(nConta),"  ","")
       If Eval(_bType,"aArquivo[1]") = "C"
          cPilha+=" Fonte: ("+aArquivo[1]+")"
       EndIf
       If Eval(_bType,"aData[1]") = "D"
          cPilha+=" "+DTOC(aData[1])
       EndIf
       If Eval(_bType,"aHora[1]") = "C"
          cPilha+=" "+aHora[1]
       EndIf
       If Eval(_bType,"aLinha[1]") = "C"
          cPilha+=" linha " +aLinha[1]
       EndIf
       cPilhaS+=cPilha+CHR(13)+CHR(10)
    EndIf
    nConta++
 ENDDO
RETURN cPilhas

/*
===============================================================================================================================
Programa--------: ROMS004O
Autor-----------: Julio de Paula Paz
Data da Criacao-: 21/08/2025
Descrição-------: Verifica de existe algum pedido de vendas na carga do tipo Agendado com multa. Se existir retorna mensagem
                  para exibir no relatório da carga.
Parametros------: _cFilCarga = Filial da Carga
                  _cCodCarga = Numero da Carga
Retorno---------: _cRet  = Vazio ou Mensagem a ser impresso no relatório da carga.
===============================================================================================================================
*/
User Function ROMS004O(_cFilCarga As Char, _cCodCarga As Char) As Char
 Local _cRet := "" As Char

 Begin Sequence
    DAI->(DbSetOrder(1)) // DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
    SC5->(DbSetOrder(1)) // C5_FILIAL+C5_NUM

    DAI->(MsSeek(_cFilCarga+_cCodCarga))

   While ! DAI->(Eof()) .And. DAI->DAI_FILIAL+DAI->DAI_COD == _cFilCarga+_cCodCarga
       If SC5->(MsSeek(DAI->DAI_FILIAL + DAI->DAI_PEDIDO))
          If SC5->C5_I_AGEND == "M"
             _cRet := "CARGA COM MULTA"
          EndIf
       EndIf

       DAI->(DBSkip())
    EndDo

 End Sequence

Return _cRet
