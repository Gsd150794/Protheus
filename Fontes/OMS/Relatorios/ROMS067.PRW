/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |31/07/2024| Chamado 47262. Jerry. Adicionado o paraemtro de Transportador e Operador Log.
Alex Wallauer |02/08/2024| Chamado 47262. Jerry. Correção dos dados dos campos WK_CNPJTRA / TA2_EST / TA2_MUN.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/
#Include "TOTVS.ch"

/*   
===============================================================================================================================
Programa----------: ROMS067
Autor-------------: Alex Wallauer
Data da Criacao---: 05/05/2022
===============================================================================================================================
Descrição---------: Relatório faturamento para a logistica. CHAMADO 39851 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS067()
Local _nI        := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| If(MV_PAR02 >= MV_PAR01 ,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }
Local _lRet      := .F.
Local aOptions   := {"1 - Sim","2 - Nao"}
Local aOptionF   := {"1-No Carregamento","2-No Faturamento"}

Private _cTitulo := "Relatório faturamento para a logistica"
Private _aItalac_F3:={}     

MV_PAR01 := CTOD("")
MV_PAR02 := Date()
MV_PAR09 := Space(6)
MV_PAR10 := Space(Len(SF2->F2_I_LTRA))
MV_PAR11 := Space(6)
MV_PAR12 := Space(Len(SF2->F2_I_LTRA))
                 //       1           2         3                      4                      5          6                      7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave            , _nCpoDesc              ,_bCondTab    , _cTitAux           , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR08"   ,"ZB4"	,                       ,                        ,             ,"Tipo de Operacao"} )

aAdd( _aParAux , { 1 , "Data de"	               , MV_PAR01, "@D"	, ""  , "", "" , 50       , .T. } ) //01
aAdd( _aParAux , { 1 , "Data ate"               , MV_PAR02, "@D"	, ""  , "", "" , 50       , .F. } ) //02
aAdd( _aParAux , { 2 , "Calcular Pallets"       ,"1"  ,aOptions  ,                  65 ,".T.", .T. } ) //03
aAdd( _aParAux , { 2 , "Valor de Frete"         ,"1"  ,aOptionF  ,                  65 ,".T.", .T. } ) //03
aAdd( _aParAux , { 1 , "UF"                     , MV_PAR05, "@!"  , ""  ,"LSTEST", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Gerente"                , MV_PAR06, "@!"  , ""  ,"LSTGER", "" , 100 , .F. } ) 
aAdd( _aParAux , { 2 , "Mostra Armazens"        ,"1"  ,{"1 - Nao","2 - Sim"}  ,                  65 ,".T.", .T. } ) //03
aAdd( _aParAux , { 1 , "Tipo de Operação"       , MV_PAR08, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Transportador"          , MV_PAR09, "@!", ""    , "SA2_05", ""    ,60      , .F. } )
aAdd( _aParAux , { 1 , "Loja"                   , MV_PAR10, "@!", ""    , "", ""          ,30      , .F. } )
aAdd( _aParAux , { 1 , "Oper. Log."             , MV_PAR11, "@!", ""    , "SA2_05", ""    ,60      , .F. } )
aAdd( _aParAux , { 1 , "Loja"                   , MV_PAR12, "@!", ""    , "", ""          ,30      , .F. } )

For _nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[_nI][03] )
Next

While .T. 

   If !ParamBox( _aParAux , _cTitulo , @_aParRet,  _bOK , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
      Exit
   Else
      MV_PAR03  :=If(ValType(MV_PAR03)="N",Str(MV_PAR03,1),LEFT(MV_PAR03,1))
      MV_PAR07  :=If(ValType(MV_PAR07)="N",Str(MV_PAR07,1),LEFT(MV_PAR07,1))

      _cTimeIni := Time()

      FWMsgRun( ,{|oProc|  _lRet := ROMS067TR(oProc) } , "Hora Inicial: "+_cTimeIni+" Emitindo Relatorio TReport... " )   

   EndIf
EndDo
Return _lRet

/*
===============================================================================================================================
Programa----------: ROMS067CT
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 22/01/2018
===============================================================================================================================
Descrição---------: Retorna a Carga Total = ao relatorio de Ordem de Carga - COPIA DA ROMS002CT
===============================================================================================================================
Parametros--------: _cProduto: SC6->C6_PRODUTO , _nQtde: SC6->C6_QTDVEN
===============================================================================================================================
Retorno-----------: Carga Total
===============================================================================================================================
*/
Static Function ROMS067CT(_cProduto,_nQtde)
Local _nQtPallet:= 0

Begin Sequence     
        //A ordem foi setada no inicio do programa
        If !SB1->(DBSeek(xFilial()+_cProduto))
           Break
        EndIf

		//================================================================================
		// Cálculo da quantidade de Pallets
		//================================================================================
		If SB1->B1_I_UMPAL == '1'
		
			_nQtPallet	:= Int( _nQtde / SB1->B1_I_CXPAL )
			
		ElseIf SB1->B1_I_UMPAL == '2'
		
			_nQtPallet	:= Int( ROMS67CNV( _nQtde , 1 , 2 ) / SB1->B1_I_CXPAL )
			
		ElseIf SB1->B1_I_UMPAL == '3'
		
			_nQtPallet	:= Int( ROMS67CNV( _nQtde , 1 , 3 ) / SB1->B1_I_CXPAL )
			
		EndIf

End Sequence

Return _nQtPallet//_cInfPal

/*
===============================================================================================================================
Programa----------: ROMS67CNV
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 22/01/2018
===============================================================================================================================
Descrição---------: Função para conversão entre unidades de medida - COPIA DA ROMS004CNV
===============================================================================================================================
Parametros--------: _nQtdAux , _nUMOri , _nUMDes
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS67CNV( _nQtdAux , _nUMOri , _nUMDes )

Local _nRet	:= 0

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
			
			_nRet := _nQtdAux * SB1->B1_I_QT3UM
			
			If SB1->B1_TIPCONV == 'D'
				_nRet := _nRet / SB1->B1_CONV
			ElseIf SB1->B1_TIPCONV == 'M'
				_nRet := _nRet * SB1->B1_CONV
			EndIf
			
		EndIf
	
	Case _nUMDes == 3
    
		//================================================================================
		// Conversão da Primeira UM para a Terceira
		//================================================================================
		If _nUMOri == 1
			
			_nRet := _nQtdAux / SB1->B1_I_QT3UM
		
		//================================================================================
		// Conversão da Segunda UM para a Terceira
		//================================================================================	
		ElseIf _nUMOri == 2
			
			If SB1->B1_TIPCONV == 'D'
				_nRet := _nQtdAux * SB1->B1_CONV
			ElseIf SB1->B1_TIPCONV == 'M'
				_nRet := _nQtdAux / SB1->B1_CONV
			EndIf
			
			_nRet := _nRet / SB1->B1_I_QT3UM
			
		EndIf

EndCase

Return( _nRet )

/*
===============================================================================================================================
Programa----------: ROMS067TR
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/08/2022
===============================================================================================================================
Descrição---------: Versão em TReport do relatório Faturamento para Logística.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS067TR(oProc)

Private _oReport, _oSect1_A
 
Begin Sequence 
  
   //====================================================================================================
   // Chama a montagem do relatório.
   //====================================================================================================	
	_oReport := ROMS067D("ROMS067D",oProc)
	_oReport:PrintDialog()

End Sequence

Return

/*
===============================================================================================================================
Programa----------: ROMS067D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/08/2022
===============================================================================================================================
Descrição---------: Realiza as definições do relatório. (ReportDef)
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS067D(_cNome,oProc)
Local _aOrder := {"Emissão"}

Begin Sequence	
   _oReport := TReport():New(_cNome,"Relatório Faturamento x Frete para Logistica",_cNome,{|_oReport| ROMS067P(_oReport,oProc)},"Relatório Faturamento para Logística")
   _oReport:SetLandscape()    
   _oReport:SetTotalInLine(.F.)

   //====================================================================================================
   // Define as totalizações e quebra por seção.
   //====================================================================================================	
 
   _oReport:SetTotalInLine(.F.)
   
   _oSect1_A := TRSection():New(_oReport, AllTrim(MV_PAR04) + " - Faturamento X Frete" , {"SF2","SC5"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_A,"F2_FILIAL"	,"TRBSF2","Filial","@D", 6)
   TRCell():New(_oSect1_A,"WK_NOMEFIL"	,"TRBSF2","Nome Filial","@!", 30)
   TRCell():New(_oSect1_A,"C5_I_OPER"	,"TRBSF2","Nat.Operacao","@!", 12)
   TRCell():New(_oSect1_A,"ZB4_DESCRI"	,"TRBSF2","Desc.Nat.Operacao","@!", 20)
   TRCell():New(_oSect1_A,"C5_I_TRCNF"	,"TRBSF2","Troca Nota","@!", 11) 
   TRCell():New(_oSect1_A,"F2_I_PEDID"	,"TRBSF2","Pedido","@!", 8) 
   TRCell():New(_oSect1_A,"C5_EMISSAO" ,"TRBSF2","Dt.Emissão Ped.","@D", 15)                   // DT. EMISSÃO PEDIDO - 
   TRCell():New(_oSect1_A,"C5_I_DTLIP" ,"TRBSF2","Dt.Lib.Preço","@D", 12)                      // DT. LIB. PREÇO -  Case  WHEN C5_I_DTLIP = ' '  THEN ' ' ElseTO_CHAR(TO_DATE(C5_I_DTLIP,'YYYYMMDD'))  END  "DT LIB.PREÇO",
   TRCell():New(_oSect1_A,"C5_I_LIBCD" ,"TRBSF2","Dt.Lib.Credito","@D", 13)                    // DT. LIB. CRÉDITO -  Case  WHEN C5_I_LIBCD = ' '  THEN ' ' ElseTO_CHAR(TO_DATE(C5_I_LIBCD,'YYYYMMDD'))  END "DT. LIB.CRÉDITO",
   TRCell():New(_oSect1_A,"F2_DOC"     ,"TRBSF2","NFE"           ,"@!", 12)                    // NFE - F2_DOC "NFE", 
   TRCell():New(_oSect1_A,"F2_EMISSAO"	,"TRBSF2","Dt.Emissão NFE","@!", 12)                    // DT. EMISSÃO NFE -  F2_DOC "NFE", Case  WHEN F2_EMISSAO = ' '  THEN ' ' ElseTO_CHAR(TO_DATE(F2_EMISSAO,'YYYYMMDD')) END "DT. EMISSAO NFE",
   TRCell():New(_oSect1_A,"C5_I_DTENT"	,"TRBSF2","Dt. Agendamento","@!", 12)                   // DT. PREVISÃO ENTREGA -Case  WHEN C5_I_DTENT = ' '  THEN ' ' ElseTO_CHAR(TO_DATE(C5_I_DTENT,'YYYYMMDD')) END "DT. PREVISÃO ENTREGA", 
   TRCell():New(_oSect1_A,"F2_I_DTRC"  , "TRBSF2","Dt. Canhoto","@!", 12)                      // DT. CANHOTO   
   TRCell():New(_oSect1_A,"ZGJ_STATUS" , "TRBSF2","Status Canhoto","@!", 12)                   // aAdd(_aItens,Posicione("ZGJ",1,SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE,"ZGJ_STATUS"))//STATUS CANHOTO - (SELECT ZGJ_STATUS FROM SIGA.ZGJ010 ZGJ WHERE ZGJ.D_E_L_E_T_ = ' ' AND ZGJ_FILIAL = F2_FILIAL AND ZGJ_NOTA = F2_DOC AND  ROWNUM = 1  ) "STATUS CANHOTO", 
   TRCell():New(_oSect1_A,"F2_I_DENOL"  , "TRBSF2","Dt Entr no OpLog","@!", 12)                // DT. OP. LOG 
   TRCell():New(_oSect1_A,"F2_CLIENTE" , "TRBSF2","Cliente","@!", 08) 
   TRCell():New(_oSect1_A,"F2_LOJA"    , "TRBSF2","Loja","@!",  05) 
   TRCell():New(_oSect1_A,"A1_NOME"    , "TRBSF2","Razão Social","@!",  50)                    // aAdd(_aItens,Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NOME"))//CLIENTE -  A1_NOME "CLIENTE", 
   TRCell():New(_oSect1_A,"A1_EST"     , "TRBSF2","UF","@!",  50 )                             // UF -  A1_EST "UF", 
   TRCell():New(_oSect1_A,"A1_MUN"     , "TRBSF2","Municipio","@!", 50)                        // CIDADE -  A1_MUN "CIDADE",
   TRCell():New(_oSect1_A,"Z21_NOME"   , "TRBSF2","Mesorregiao","@!", 50)                      // aAdd(_aItens,Posicione("Z21",4,xFilial("Z21")+CC2->CC2_EST+_cCC2_I_MESO,"Z21_NOME"))                //MESORREGIÃO - Z21_NOME "MESORREGIÃO",  // Z21_FILIAL+Z21_EST+Z21_COD
   TRCell():New(_oSect1_A,"Z22_NOME"   , "TRBSF2","Microrregiao","@!", 50)                     // aAdd(_aItens,Posicione("Z22",4,xFilial("Z22")+CC2->CC2_EST+_cCC2_I_MESO+CC2->CC2_I_MICR,"Z22_NOME"))//MICRORREGIÃO -  Z22_NOME "MICRORREGIÃO", //Z22_FILIAL+Z22_EST+Z22_MESO+Z22_COD
   TRCell():New(_oSect1_A,"F2_VOLUME1" , "TRBSF2","Volume","@E 9999,999", 08)                  // aAdd(_aItens,Transform(SF2->F2_VOLUME1,"@E 9999,999"))//QTD VOLUME -  F2_VOLUME1 "QTD VOLUME", 
   TRCell():New(_oSect1_A,"F2_ESPECI1" , "TRBSF2","Especie","@!", 20)                          // aAdd(_aItens,SF2->F2_ESPECI1)//ESPECIE -  F2_ESPECI1 "ESPECIE" , 
   TRCell():New(_oSect1_A,"F2_PLIQUI"  , "TRBSF2","Peso Liquido","@E 99,999,999.999", 12)      // aAdd(_aItens,Transform(SF2->F2_PLIQUI ,_cPictPLIQUI ))//PESO LIQ -  F2_PLIQUI "PESO LIQ", 
   TRCell():New(_oSect1_A,"F2_PBRUTO"  , "TRBSF2","Peso Bruto","@E 99,999,999.999", 12)        // aAdd(_aItens,Transform(SF2->F2_PBRUTO ,_cPictPBRUTO ))//PESO BRUTO -  F2_PBRUTO "PESO BRUTO" ,
   TRCell():New(_oSect1_A,"F2_VALMERC" , "TRBSF2","Valor Mercadoria","@E 99,999,999.999", 16)  // aAdd(_aItens,Transform(SF2->F2_VALMERC,_cPictVALMERC))//VLR MERCADORIA -  F2_VALMERC "VLR MERCADORIA", 
   TRCell():New(_oSect1_A,"F2_I_FRET"  , "TRBSF2","Valor Frete","@E 99,999,999.999", 12)       // aAdd(_aItens,Transform(_nFrete,_cPictI_FRET ))//VLR FRETE - F2_I_FRET "VLR FRETE", 
   TRCell():New(_oSect1_A,"C5_I_V3NOM" , "TRBSF2","Gerente","@!", 30)                          // aAdd(_aItens,SC5->C5_I_V3NOM)//GERENTE -  C5_I_V3NOM GERENTE, 
   TRCell():New(_oSect1_A,"C5_I_V2NOM" , "TRBSF2","Coordenador","@!", 30)                      // aAdd(_aItens,SC5->C5_I_V2NOM)//COORDENADOR -  C5_I_V2NOM COORDENADOR , 
   TRCell():New(_oSect1_A,"C5_I_V1NOM" , "TRBSF2","Vendedor","@!", 30)                         // 
   TRCell():New(_oSect1_A,"WK_CNPJTRA" , "TRBSF2","CNPJ Transportador","@!", 30)               // TRANSPORTADOR - CNPJ
   TRCell():New(_oSect1_A,"F2_I_NTRAN" , "TRBSF2","Transportador","@!", 30)                    // TRANSPORTADOR     
   TRCell():New(_oSect1_A,"A2_SIMPNAC" , "TRBSF2","Simples Nacional","@!", 16)                 // aAdd(_aItens,If(Posicione("SA2",1,xFilial("SA2")+SF2->F2_I_CTRA+SF2->F2_I_LTRA,"A2_SIMPNAC")="1","Sim","Nao"))//SIMPLES NACIONAL -  Case WHEN A2_SIMPNAC  = '1' THEN 'SIM' Else'NÃO'   END "SIMPLES NACIONAL"
   TRCell():New(_oSect1_A,"F2_I_PLACA" , "TRBSF2","Placa","@!", 10)                            // aAdd(_aItens,SF2->F2_I_PLACA)//PLACA -
   TRCell():New(_oSect1_A,"DA3_I_TPVC" , "TRBSF2","Tipo de Veiculo","@!", 10)                  // aAdd(_aItens,U_ITRetBox( Posicione("DA3",1,xFilial("DA3") + SF2->F2_I_VEICU,"DA3_I_TPVC") , "DA3_I_TPVC" ))//TIPO DE VEICULO - 
   TRCell():New(_oSect1_A,"TA2_EST"    , "TRBSF2","UF Transportador","@!", 10)                 // UF Transportador
   TRCell():New(_oSect1_A,"TA2_MUN"    , "TRBSF2","Municipio Transp.","@!", 50)                // Municipio Trans portador 
   TRCell():New(_oSect1_A,"WK_QTDPALL" , "TRBSF2","Qtd.Pallets","@E 99,999,999.99", 11)        // Quantidade Pallets
   TRCell():New(_oSect1_A,"C5_I_FILFT", "TRBSF2","Fil.Faturamento","@!", 10)                   // Filial de Faturamento
   TRCell():New(_oSect1_A,"C5_I_PDFT" , "TRBSF2","Ped.Faturamento","@!", 10)                   // Pedido de Faturamento
   TRCell():New(_oSect1_A,"C5_I_FLFNC", "TRBSF2","Fil.Carregamento","@!", 10)                  // Filial de Carregamento
   TRCell():New(_oSect1_A,"C5_I_PDPR" , "TRBSF2","Ped.Carregamento","@!", 10)                  // Pedido de Carregamento
   TRCell():New(_oSect1_A,"C5_CLIENTE", "TRBSF2","Cliente Carr.","@!", 12)                     // Cliente Carregamento
   TRCell():New(_oSect1_A,"WK_LOJCLIE", "TRBSF2","Loja Cli Carregam.","@!", 12)                // Loja Cliente Carregamento
   TRCell():New(_oSect1_A,"WK_NCLICAR", "TRBSF2","Nome Cli Carregam.","@!", 40)                // Nom3 Clien. Carregamento.
   TRCell():New(_oSect1_A,"WK_NFE"    , "TRBSF2","Nfe Vinculada","@!", 30)                     // Nfe da Remessa/Venda Triangular
   TRCell():New(_oSect1_A,"WK_CNPJOPL", "TRBSF2","CNPJ Oper.Logis","@!", 10)                   // CNPJ Operador Logistico.
   TRCell():New(_oSect1_A,"WK_NOMEOPL", "TRBSF2","Nome Oper.Logis","@!", 10)                   // CNPJ Operador Logistico.
   TRCell():New(_oSect1_A,"WK_MUNOPL" , "TRBSF2","Municip.Oper.Logis","@!", 30)                // Municipio Operador Logistico
   TRCell():New(_oSect1_A,"WK_UFOPL"  , "TRBSF2","UF Oper.Logis","@!", 14)                     // UF Operador Logistico
   TRCell():New(_oSect1_A,"F2_TPFRETE", "TRBSF2","Tipo de Frete","@!", 14)                     // Tipo de Frete
   TRCell():New(_oSect1_A,"F2_CARGA"  , "TRBSF2","Ordem de carga","@!", 7)                     // Ordem de Carga
   TRCell():New(_oSect1_A,"E1_VENCREA", "TRBSF2","DT VENCTO TITULO/NF","@D", 08)
   TRCell():New(_oSect1_A,"C5_I_TIPCA", "TRBSF2","TIPO DE CARGA"      ,"@!", 15)
   If Subs(MV_PAR07,1,1) == "2"
      TRCell():New(_oSect1_A,"D2_LOCAL"  , "TRBSF2","Local","@!", 30)                        // Local
   EndIf
   TRCell():New(_oSect1_A,"F2_I_LOCEM", "TRBSF2","Local de Embarque","@!", 8)                
   TRCell():New(_oSect1_A,"ZEL_DESCRI", "TRBSF2","Nome Loc Embarque","@!", 30) 
   TRCell():New(_oSect1_A,"F2_I_PENOL", "TRBSF2","Prev Entr Op Log","@!", 8)                 // prev entrega Operador Logístico.
   TRCell():New(_oSect1_A,"F2_I_DENOL", "TRBSF2","Dt Entr Op Log","@!", 14)                  // Data entrega Operador Logístico.
   TRCell():New(_oSect1_A,"F2_I_PENCL", "TRBSF2","Prev Entr Cliente","@!", 8)                // Prz Ent Cli EDI
   TRCell():New(_oSect1_A,"F2_I_DENCL", "TRBSF2","Dt Entr Cliente EDI","@!", 14)             // Data entrega Cliente
   TRCell():New(_oSect1_A,"F2_I_DTRC" , "TRBSF2","Dt. Canhoto","@!", 12)                     // DT. CANHOTO   
   TRCell():New(_oSect1_A,"F2_I_TT1TR", "TRBSF2","Transit Time 1° Trecho","@!", 8)           // Transit Time 1° Trecho
   TRCell():New(_oSect1_A,"F2_I_TT2TR", "TRBSF2","Transit Time 2° Trecho","@!", 8)           // Transit Time 2° Trecho 
   TRCell():New(_oSect1_A,"C5_I_AGEND", "TRBSF2","Tipo de Entrega","@!", 30) 
   TRCell():New(_oSect1_A,"F2_I_DTOP" , "TRBSF2","Entrega no OL (Dt.Canhoto)","@!", 14)      // Entrega no OL (Dt.Canhoto)

   _oSect1_A:SetTotalText(" ") 
   _oSect1_A:Disable()

End Sequence
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------: ROMS067P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/08/2022
===============================================================================================================================
Descrição---------: Realiza a impressão do relatório. (ReportPrint)
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS067P(_oReport,oProc)
Local _cQry := ""		
Local _cNomeFil
Local _cOperTria := AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))
Local _nI
Local _nFrete:=0
Local _cLocal := ""

Local _cFilFatur := ""
Local _cPedFatur := ""
Local _cFilcarre := ""
Local _cPedCarre := ""
Local _cCliCarre := ""
Local _cLojCarre := ""
Local _cNomCarre := ""  
Local _NfCarre   := ""
  
Begin Sequence                    
   //====================================================================================================
   // Ativa a seção do relatório conforme a ordem de emissão do relatório.
   //====================================================================================================	
   _nOrdReport := _oReport:GetOrder()
   _oSect1_A:Enable() 
    
   //====================================================================================================
   // Monta a query de dados.
   //====================================================================================================	
   _cQry := "SELECT DISTINCT F2_FILIAL,  "
   _cQry += "SF2.F2_DOC,  "
   _cQry += "SF2.F2_SERIE,  "
   _cQry += "SF2.F2_EMISSAO,  "
   _cQry += "SF2.F2_CLIENTE,  "
   _cQry += "SF2.F2_LOJA,  "
   _cQry += "SA1.A1_NOME,  "
   _cQry += "SA1.A1_EST, "
   _cQry += "SA1.A1_MUN, "
   _cQry += "SA1.A1_COD_MUN, "
   _cQry += "SF2.F2_I_CTRA,  "
   _cQry += "SF2.F2_I_LTRA,  "
   
   _cQry += "SA2T.A2_NOME,   "
   _cQry += "SA2T.A2_CGC,    "
   _cQry += "SA2T.A2_EST,    "
   _cQry += "SA2T.A2_MUN,    "
   _cQry += "SA2T.A2_SIMPNAC, "
   
   _cQry += "SF2.F2_I_DTRC,  "
   _cQry += "SF2.F2_I_DENOL,  "
   _cQry += "SF2.F2_VALBRUT,  "
   _cQry += "SF2.F2_VALMERC,  "
   _cQry += "SF2.F2_I_PEDID,  "
   _cQry += "SC5.C5_NUM, "
   _cQry += "SC5.C5_I_OPER,  "
   _cQry += "SC5.C5_I_NFSED,  " 
   _cQry += "SC5.C5_TPFRETE, "
   _cQry += "SC5.C5_I_TRCNF, "
   _cQry += "SC5.C5_EMISSAO, "
   _cQry += "SC5.C5_I_DTLIP, "
   _cQry += "SC5.C5_I_LIBCD, "
   _cQry += "SC5.C5_I_DTENT, "
   _cQry += "SC5.C5_I_PVREM, "
   _cQry += "SC5.C5_FILIAL, "
   _cQry += "SF2.F2_I_VEICU, "
   _cQry += "SF2.F2_VOLUME1, "
   _cQry += "SF2.F2_ESPECI1, "
   _cQry += "SF2.F2_PLIQUI,  "
   _cQry += "SF2.F2_PBRUTO,  "
   _cQry += "SF2.F2_I_FRET,  "
   _cQry += "SC5.C5_I_V3NOM, "
   _cQry += "SC5.C5_I_V2NOM, "
   _cQry += "SC5.C5_I_V1NOM, "   
   _cQry += "SC5.C5_I_TIPCA, "
   _cQry += "SF2.F2_I_NTRAN, "
   _cQry += "SF2.F2_I_PLACA, "
   _cQry += "SC5.C5_I_FILFT, "
   _cQry += "SC5.C5_I_PVFAT, " 
   _cQry += "SC5.C5_I_PDFT,  "
   _cQry += "SC5.C5_I_FLFNC, "
   _cQry += "SC5.C5_I_PDPR,  "
   _cQry += "SC5.C5_CLIENTE, "
   _cQry += "SF2.F2_I_DENCL, "
   _cQry += "SF2.F2_I_DENOL, SF2.F2_TPFRETE ,  SF2.F2_CARGA ," 

   _cQry += "SF2.F2_I_LOCEM, "
   _cQry += "ZEL.ZEL_DESCRI , "
   _cQry += "SF2.F2_I_PENOL , "
   _cQry += "SF2.F2_I_PENCL , "
   _cQry += "SF2.F2_I_TT1TR , "
   _cQry += "SF2.F2_I_TT2TR , "
   _cQry += "SF2.F2_I_DTOP  , "   
   _cQry += "SC5.C5_I_AGEND , "

   _cQry += "Case F2_I_REDP "
   _cQry += "       WHEN ' ' "
   _cQry += "       THEN "
   _cQry += "          (SELECT A2_NOME FROM "+ RetSqlName("SA2") +" SA2A "
   _cQry += "           WHERE A2_FILIAL = ' ' "
   _cQry += "            AND   A2_COD    = F2_I_OPER "
   _cQry += "            AND   A2_LOJA   = F2_I_OPLO "
   _cQry += "            AND SA2A.D_E_L_E_T_ = ' ') "
   _cQry += "       Else"
   _cQry += "           (SELECT A2_NOME FROM "+ RetSqlName("SA2") +" SA2B "
   _cQry += "            WHERE A2_FILIAL = ' ' "
   _cQry += "            AND   A2_COD    = F2_I_REDP "
   _cQry += "            AND   A2_LOJA   = F2_I_RELO "
   _cQry += "            AND SA2B.D_E_L_E_T_ = ' ') "
   _cQry += "       END NOME_OPER, "

   _cQry += "Case F2_I_REDP "
   _cQry += "       WHEN ' ' "
   _cQry += "       THEN "
   _cQry += "          (SELECT A2_EST FROM "+ RetSqlName("SA2") +" SA2C "
   _cQry += "           WHERE A2_FILIAL = ' ' "
   _cQry += "            AND   A2_COD    = F2_I_OPER "
   _cQry += "            AND   A2_LOJA   = F2_I_OPLO "
   _cQry += "            AND SA2C.D_E_L_E_T_ = ' ') "
   _cQry += "       Else"
   _cQry += "           (SELECT A2_EST FROM "+ RetSqlName("SA2") +" SA2D "
   _cQry += "            WHERE A2_FILIAL = ' ' "
   _cQry += "            AND   A2_COD    = F2_I_REDP "
   _cQry += "            AND   A2_LOJA   = F2_I_RELO "
   _cQry += "            AND SA2D.D_E_L_E_T_ = ' ') "
   _cQry += "       END EST_OPER, "
   
   _cQry += "Case F2_I_REDP "
   _cQry += "       WHEN ' ' "
   _cQry += "       THEN "
   _cQry += "          (SELECT A2_MUN FROM "+ RetSqlName("SA2") +" SA2E "
   _cQry += "           WHERE A2_FILIAL = ' ' "
   _cQry += "            AND   A2_COD    = F2_I_OPER "
   _cQry += "            AND   A2_LOJA   = F2_I_OPLO "
   _cQry += "            AND SA2E.D_E_L_E_T_ = ' ') "
   _cQry += "       Else"
   _cQry += "           (SELECT A2_MUN FROM "+ RetSqlName("SA2") +" SA2F "
   _cQry += "            WHERE A2_FILIAL = ' ' "
   _cQry += "            AND   A2_COD    = F2_I_REDP "
   _cQry += "            AND   A2_LOJA   = F2_I_RELO "
   _cQry += "            AND SA2F.D_E_L_E_T_ = ' ') "
   _cQry += "       END MUN_OPER, "

   _cQry += "Case F2_I_REDP "
   _cQry += "       WHEN ' ' "
   _cQry += "       THEN "
   _cQry += "          (SELECT A2_CGC FROM "+ RetSqlName("SA2") +" SA2G "
   _cQry += "           WHERE A2_FILIAL = ' ' "
   _cQry += "            AND   A2_COD    = F2_I_OPER "
   _cQry += "            AND   A2_LOJA   = F2_I_OPLO "
   _cQry += "            AND SA2G.D_E_L_E_T_ = ' ') "
   _cQry += "       Else"
   _cQry += "           (SELECT A2_CGC FROM "+ RetSqlName("SA2") +" SA2H "
   _cQry += "            WHERE A2_FILIAL = ' ' "
   _cQry += "            AND   A2_COD    = F2_I_REDP "
   _cQry += "            AND   A2_LOJA   = F2_I_RELO "
   _cQry += "            AND SA2H.D_E_L_E_T_ = ' ') "
   _cQry += "       END CGC_OPER, "

   _cQry += "Case F2_DUPL "
   _cQry += "       WHEN ' ' "
   _cQry += "       THEN "
   _cQry += "          ' ' "
   _cQry += "       Else"
   _cQry += "           (SELECT E1_VENCREA FROM SE1010 SE1 "
   _cQry += "            WHERE E1_FILIAL  = F2_FILIAL "
   _cQry += "            AND   E1_CLIENTE = F2_CLIENTE "
   _cQry += "            AND   E1_LOJA    = F2_LOJA "
   _cQry += "            AND   E1_PREFIXO = F2_SERIE "
   _cQry += "            AND   E1_NUM     = F2_DOC "
   _cQry += "            AND   ROWNUM = 1 "
   _cQry += "            AND SE1.D_E_L_E_T_ = ' ') "
   _cQry += "       END E1_VENCREA, "

   _cQry += "           (SELECT DAI_I_TIPC FROM DAI010 DAI "
   _cQry += "            WHERE DAI_FILIAL  = F2_FILIAL "
   _cQry += "            AND   DAI_PEDIDO = F2_I_PEDID "
   _cQry += "            AND   ROWNUM = 1 "
   _cQry += "            AND   DAI.D_E_L_E_T_ = ' ') "
   _cQry += "       AS DAI_I_TIPC, "

   _cQry += "SF2.R_E_C_N_O_ RECSF2 , SC5.R_E_C_N_O_  RECSC5,  "
   _cQry += "ZB4.ZB4_DESCRI, ZGJ_STATUS, Z21_NOME, Z22_NOME "

   _cQry += " FROM " + RetSqlName("SF2") + " SF2, " + RetSqlName("SA1") +" SA1, " + RetSqlName("SA2") +" SA2T, " // + RetSqlName("SA2") +" SA2_B, " 
   _cQry += RetSqlName("SC5")+" SC5, " + RetSqlName("ZB4") +" ZB4, " + RetSqlName("ZGJ") +" ZGJ, " + RetSqlName("CC2") +" CC2, " + RetSqlName("Z21") +" Z21, " + RetSqlName("Z22") +" Z22 , " + RetSqlName("ZEL") +" ZEL "
   //_cQry += " LEFT JOIN "+ RetSqlName("SA2") +" SA2T ON SF2.F2_I_CTRA  = SA2T.A2_COD	AND SF2.F2_I_LTRA  = SA2T.A2_LOJA "

   _cQry += " WHERE SF2.D_E_L_E_T_ = ' ' AND SA1.D_E_L_E_T_ = ' ' AND SC5.D_E_L_E_T_ = ' ' "
   _cQry += " AND SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA = SA1.A1_LOJA AND SA1.A1_FILIAL = ' ' "
   _cQry += " AND SA2T.A2_COD (+) = SF2.F2_I_CTRA AND SA2T.A2_LOJA (+) =  SF2.F2_I_LTRA AND SA2T.D_E_L_E_T_ (+) <> '*' "
   _cQry += " AND SF2.F2_FILIAL = SC5.C5_FILIAL AND SF2.F2_I_PEDID = SC5.C5_NUM "
   _cQry += " AND SC5.C5_TIPO = 'N' "
   _cQry += " AND ZB4.ZB4_FILIAL = ' ' AND ZB4.ZB4_COD = SC5.C5_I_OPER AND ZB4.D_E_L_E_T_ = ' ' "
   _cQry += " AND ZGJ.ZGJ_FILIAL (+) = SF2.F2_FILIAL AND ZGJ.ZGJ_NOTA (+)  = SF2.F2_DOC AND ZGJ.ZGJ_SERIE (+)  = SF2.F2_SERIE AND ZGJ.D_E_L_E_T_ (+) <> '*' " 
 
   _cQry += " AND CC2_FILIAL     = ' '        "
   _cQry += " AND CC2_EST        = SA1.A1_EST "
   _cQry += " AND CC2_CODMUN     = SA1.A1_COD_MUN "
   _cQry += " AND CC2.D_E_L_E_T_ = ' '        "

   _cQry += " AND Z22.D_E_L_E_T_ (+) = ' ' "
   _cQry += " AND Z22.Z22_FILIAL     (+) = ' ' "
   _cQry += " AND Z22.Z22_EST        (+) = CC2.CC2_EST    "
   _cQry += " AND Z22.Z22_MESO       (+) = CC2.CC2_I_MESO "
   _cQry += " AND Z22.Z22_COD        (+) = CC2.CC2_I_MICR "

   _cQry += " AND Z21.Z21_FILIAL     (+) = ' ' "
   _cQry += " AND Z21.Z21_EST        (+) = CC2_EST "
   _cQry += " AND Z21.Z21_COD        (+) = CC2_I_MESO "
   _cQry += " AND Z21.D_E_L_E_T_ (+) = ' ' "

   _cQry += " AND ZEL.ZEL_FILIAL     (+) = ' ' "
   _cQry += " AND ZEL.ZEL_CODIGO     (+) = F2_I_LOCEM "

   If ! Empty(MV_PAR01) // De Emissão
      _cQry += " AND SF2.F2_EMISSAO >= '" + DToS(MV_PAR01) +"' "
   EndIf 

   If ! Empty(MV_PAR02) // Até Emissão
      _cQry += " AND SF2.F2_EMISSAO <= '" + DToS(MV_PAR02) +"' "
   EndIf    

   If ! Empty(MV_PAR05) // Estado
      _cQry += " AND SA1.A1_EST IN "+ FormatIn(MV_PAR05,";")
   EndIf    

   If ! Empty(MV_PAR06) // Gerente
      _cQry += " AND SC5.C5_VEND3 IN "+ FormatIn(MV_PAR06,";")
   EndIf

   If !Empty(MV_PAR08)
      MV_PAR08 := AllTrim(MV_PAR08)
      If Len(MV_PAR08) = 2
         _cQry += " AND SC5.C5_I_OPER = '"+MV_PAR08+"' "
      Else
         _cQry += " AND SC5.C5_I_OPER IN " + FormatIn(AllTrim(MV_PAR08),";") + " "
      EndIf
   EndIf

   If !Empty(MV_PAR09)
      _cQry += " AND SF2.F2_I_CTRA = '"+MV_PAR09+"' "
      If !Empty(MV_PAR10)
         _cQry += " AND SF2.F2_I_LTRA = '"+MV_PAR10+"' "
      EndIf
   EndIf

   If !Empty(MV_PAR11)
      _cQry += " AND (SF2.F2_I_OPER = '"+MV_PAR11+"' OR SF2.F2_I_REDP  = '"+MV_PAR11+"') "
      If !Empty(MV_PAR12)
         _cQry += " AND (SF2.F2_I_OPLO  = '"+MV_PAR12+"'  OR SF2.F2_I_RELO  = '"+MV_PAR12+"') " 
      EndIf
   EndIf

   _cQry += " ORDER BY SF2.F2_FILIAL, SF2.F2_EMISSAO, SF2.F2_DOC  "

   If Select("TRBSF2") <> 0
	  TRBSF2->(DBCloseArea())
   EndIf 
	_cQry := ChangeQuery(_cQry)
   MPSysOpenQuery(_cQry,"TRBSF2")
   
   TCSetField('TRBSF2',"C5_EMISSAO","D",8,0)  // DT. EMISSÃO PEDIDO 
   TCSetField('TRBSF2',"C5_I_DTLIP","D",8,0)  // DT. LIB. PREÇO 
   TCSetField('TRBSF2',"C5_I_LIBCD","D",8,0)  // DT. LIB. CRÉDITO 
   TCSetField('TRBSF2',"F2_I_DTRC" ,"D",8,0)
   TCSetField('TRBSF2',"C5_I_DTLIP","D",8,0)  // DT. LIB. PREÇO 
   TCSetField('TRBSF2',"F2_EMISSAO","D",8,0)  // DT. EMISSÃO NFE
   TCSetField('TRBSF2',"C5_I_DTENT","D",8,0)  // DT. PREVISÃO ENTREGA
   TCSetField('TRBSF2',"F2_I_DENCL","D",8,0)  // Data entrega Cliente 
   TCSetField('TRBSF2',"F2_I_DENOL","D",8,0)  // Data entrega Operador Logístico.
   TCSetField('TRBSF2',"F2_I_DTOP" ,"D",8,0)  // Entrega no OL (Dt.Canhoto)
   TCSetField('TRBSF2',"F2_I_PENOL","D",8,0)
   TCSetField('TRBSF2',"F2_I_PENCL","D",8,0)
   	 
   DBSelectArea("TRBSF2")
   TRBSF2->(DBGoTop()) 

   Count To _ntotRegs	
   
   _oReport:SetMeter(_ntotRegs)	
   
   SD2->(DBSetOrder(3))
   SB1->(DBSetOrder(1))
   SF2->(DBORDERNICKNAME("IT_I_PEDID"))
   SA2->(DBSetOrder(1)) 
   DAI->(DBSetOrder(4)) 

   TRBSF2->(DBGoTop())

   //====================================================================================================
   // Inicia processo de impressão.
   //====================================================================================================	
   _nI := 0

   While !TRBSF2->(Eof())
		
      If _oReport:Cancel()
		   Exit
      EndIf
					
      //====================================================================================================
      // Inicializando a primeira seção
      //====================================================================================================		 
      _oSect1_A:Init()

	   _oReport:IncMeter()
      _oReport:SetMsgPrint('Lendo: '+AllTrim(Str(_nI)) + " de " + AllTrim(Str(_ntotRegs)))
      _nI++
      oProc:cCaption := ('Lendo: '+AllTrim(Str(_nI)) + " de " + AllTrim(Str(_ntotRegs)) )
      ProcessMessages()
	          
      //====================================================================================================
      // Imprimindo... 
      //====================================================================================================		 
      _dData  := TRBSF2->F2_EMISSAO
      //IncProc("Imprimindo Data Emissão: "+DToC(_dData))

      _cNomeFil := AllTrim(FWFilialName(cEmpAnt,TRBSF2->F2_FILIAL,1))

      SF2->(DBGoTo(TRBSF2->RECSF2))
      //SC5->(DBGoTo(TRBSF2->RECSC5))

      _nFrete    :=TRBSF2->F2_I_FRET

      
      If TRBSF2->C5_I_TRCNF = 'S' 
         _cFilFatur := TRBSF2->C5_I_FILFT
         _cPedFatur := TRBSF2->C5_I_PDFT
         _cFilcarre := TRBSF2->C5_I_FLFNC
         _cPedCarre := TRBSF2->C5_I_PDPR
        
         _cCliCarre := ""
         _cLojCarre := ""
         _cNomCarre := ""
         _NfCarre   := ""
    

         If TRBSF2->C5_I_PDFT == TRBSF2->C5_NUM //ESTOU NO DE Faturamento
            _cCliCarre := Posicione("SC5",1,TRBSF2->C5_I_FLFNC+TRBSF2->C5_I_PDPR,"C5_CLIENTE")
            _cLojCarre := SC5->C5_LOJACLI
            _NfCarre   := SC5->C5_NOTA
            _cNomCarre := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_NOME")

            If MV_PAR04 = "2"
               _cPedCarregamento:=SC5->C5_I_FLFNC+SC5->C5_I_PDPR//Busca o de Carregamento
               SF2->(DBSeek(_cPedCarregamento))
               _nFrete:=SF2->F2_I_FRET
            EndIf

         ElseIf SC5->C5_I_PDPR = SC5->C5_NUM //ESTOU NO DE Carregamento
            _cCliCarre := Posicione("SC5",1,TRBSF2->C5_I_FILFT+TRBSF2->C5_I_PDFT,"C5_CLIENTE")
            _cLojCarre := SC5->C5_LOJACLI
             _NfCarre  := SC5->C5_NOTA
            _cNomCarre := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_NOME")
            If MV_PAR04 = "2"
               _nFrete:=0
            EndIf
         EndIf 

      ElseIf TRBSF2->C5_I_OPER $ _cOperTria // Tipos de operações da operação trigular

         If !Empty(TRBSF2->C5_I_PVREM) // Oper 05-Vendas
            _cCliCarre := Posicione("SC5",1,TRBSF2->C5_FILIAL+TRBSF2->C5_I_PVREM,"C5_CLIENTE")
            _cLojCarre := SC5->C5_LOJACLI
            _NfCarre   := SC5->C5_NOTA
            _cNomCarre := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_NOME")
            If MV_PAR04 = "2"
               _cPedCarregamento:=TRBSF2->C5_FILIAL+TRBSF2->C5_I_PVREM//Busca o de Carregamento
               SF2->(DBSeek(_cPedCarregamento))
               _nFrete:=SF2->F2_I_FRET
            EndIf
         ElseIf !Empty(TRBSF2->C5_I_PVFAT) // Oper 42-Remessa
            _cCliCarre := Posicione("SC5",1,TRBSF2->C5_FILIAL+TRBSF2->C5_I_PVFAT,"C5_CLIENTE")
            _cLojCarre := SC5->C5_LOJACLI
            _NfCarre   := SC5->C5_NOTA
            _cNomCarre := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_NOME") 
            If MV_PAR04 = "2"
               _nFrete:=0
            EndIf             
         EndIf
      EndIf

      _oSect1_A:Cell("F2_FILIAL"):SetValue(TRBSF2->F2_FILIAL)
      _oSect1_A:Cell("WK_NOMEFIL"):SetValue(_cNomeFil)
      _oSect1_A:Cell("C5_I_OPER"):SetValue(TRBSF2->C5_I_OPER)
      _oSect1_A:Cell("ZB4_DESCRI"):SetValue(TRBSF2->ZB4_DESCRI)
      _oSect1_A:Cell("C5_I_TRCNF"):SetValue(If(TRBSF2->C5_I_TRCNF == "S","SIM","NÃO")) 
      _oSect1_A:Cell("F2_I_PEDID"):SetValue(TRBSF2->F2_I_PEDID) 
      _oSect1_A:Cell("C5_EMISSAO"):SetValue(TRBSF2->C5_EMISSAO)    // DT. EMISSÃO PEDIDO - 
      _oSect1_A:Cell("C5_I_DTLIP"):SetValue(TRBSF2->C5_I_DTLIP)    // DT. LIB. PREÇO -  Case  WHEN C5_I_DTLIP = ' '  THEN ' ' ElseTO_CHAR(TO_DATE(C5_I_DTLIP,'YYYYMMDD'))  END  "DT LIB.PREÇO",
      _oSect1_A:Cell("C5_I_LIBCD"):SetValue(TRBSF2->C5_I_LIBCD)    // DT. LIB. CRÉDITO -  Case  WHEN C5_I_LIBCD = ' '  THEN ' ' ElseTO_CHAR(TO_DATE(C5_I_LIBCD,'YYYYMMDD'))  END "DT. LIB.CRÉDITO",
      _oSect1_A:Cell("F2_DOC")    :SetValue(TRBSF2->F2_DOC)        // NFE - F2_DOC "NFE", 
      _oSect1_A:Cell("F2_EMISSAO"):SetValue(TRBSF2->F2_EMISSAO)    // DT. EMISSÃO NFE -  F2_DOC "NFE", Case  WHEN F2_EMISSAO = ' '  THEN ' ' ElseTO_CHAR(TO_DATE(F2_EMISSAO,'YYYYMMDD')) END "DT. EMISSAO NFE",
      _oSect1_A:Cell("C5_I_DTENT"):SetValue(TRBSF2->C5_I_DTENT)    // DT. PREVISÃO ENTREGA -Case  WHEN C5_I_DTENT = ' '  THEN ' ' ElseTO_CHAR(TO_DATE(C5_I_DTENT,'YYYYMMDD')) END "DT. PREVISÃO ENTREGA", 
      _oSect1_A:Cell("F2_I_DTRC") :SetValue(TRBSF2->F2_I_DTRC)     // DT. CANHOTO - Case  WHEN F2_I_DTRC = ' '   THEN ' ' ElseTO_CHAR(TO_DATE(F2_I_DTRC,'YYYYMMDD'))  END "DT. CANHOTO",
      _oSect1_A:Cell("ZGJ_STATUS"):SetValue(TRBSF2->ZGJ_STATUS)    // STATUS CANHOTO       
      _oSect1_A:Cell("F2_I_DENOL"):SetValue(TRBSF2->F2_I_DENOL)    // DT. CANHOTO OPER LOG
      _oSect1_A:Cell("F2_CLIENTE"):SetValue(TRBSF2->F2_CLIENTE) 
      _oSect1_A:Cell("F2_LOJA")   :SetValue(TRBSF2->F2_LOJA) 
      _oSect1_A:Cell("A1_NOME")   :SetValue(TRBSF2->A1_NOME)       // CLIENTE -  A1_NOME "CLIENTE", 
      _oSect1_A:Cell("A1_EST")    :SetValue(TRBSF2->A1_EST)        // UF -  A1_EST "UF", 
      _oSect1_A:Cell("A1_MUN")    :SetValue(TRBSF2->A1_MUN)        // CIDADE -  A1_MUN "CIDADE",
      _oSect1_A:Cell("Z21_NOME")  :SetValue(TRBSF2->Z21_NOME)      // MESORREGIÃO  - Z21_NOME "MESORREGIÃO",  // Z21_FILIAL+Z21_EST+Z21_COD
      _oSect1_A:Cell("Z22_NOME")  :SetValue(TRBSF2->Z22_NOME)      // MICRORREGIÃO -  Z22_NOME "MICRORREGIÃO", //Z22_FILIAL+Z22_EST+Z22_MESO+Z22_COD
      _oSect1_A:Cell("F2_VOLUME1"):SetValue(TRBSF2->F2_VOLUME1)    // QTD VOLUME   -  F2_VOLUME1 "QTD VOLUME", 
      _oSect1_A:Cell("F2_ESPECI1"):SetValue(TRBSF2->F2_ESPECI1)    // "ESPECIE"  
      _oSect1_A:Cell("F2_PLIQUI") :SetValue(TRBSF2->F2_PLIQUI)     // PESO LIQ -  F2_PLIQUI "PESO LIQ", 
      _oSect1_A:Cell("F2_PBRUTO") :SetValue(TRBSF2->F2_PBRUTO)     // PESO BRUTO" ,
      _oSect1_A:Cell("F2_VALMERC"):SetValue(TRBSF2->F2_VALMERC)    // VLR MERCADORIA -  F2_VALMERC "VLR MERCADORIA", 
      _oSect1_A:Cell("F2_I_FRET") :SetValue(_nFrete)               // VLR FRETE - F2_I_FRET "VLR FRETE", 
      _oSect1_A:Cell("C5_I_V3NOM"):SetValue(TRBSF2->C5_I_V3NOM)    // GERENTE -  C5_I_V3NOM GERENTE, 
      _oSect1_A:Cell("C5_I_V2NOM"):SetValue(TRBSF2->C5_I_V2NOM)    // COORDENADOR -  C5_I_V2NOM COORDENADOR , 
      _oSect1_A:Cell("C5_I_V1NOM"):SetValue(TRBSF2->C5_I_V1NOM)    // VENDEDOR
      _oSect1_A:Cell("F2_I_NTRAN"):SetValue(TRBSF2->F2_I_NTRAN)    // TRANSPORTADOR -  F2_I_NTRAN "TRANSPORTADOR",        
      _oSect1_A:Cell("A2_SIMPNAC"):SetValue(If(TRBSF2->A2_SIMPNAC == "1","SIM","NÃO"))            // SIMPLES NACIONAL -  Case WHEN A2_SIMPNAC  = '1' THEN 'SIM' Else'NÃO'   END "SIMPLES NACIONAL"
      _oSect1_A:Cell("F2_I_PLACA"):SetValue(TRBSF2->F2_I_PLACA)    // PLACA 

      _NMRetBox := U_ITRetBox( Posicione("DA3",1,xFilial("DA3") + TRBSF2->F2_I_VEICU,"DA3_I_TPVC") , "DA3_I_TPVC" )

      _oSect1_A:Cell("DA3_I_TPVC"):SetValue(_NMRetBox)      // TIPO DE VEICULO - 
      _oSect1_A:Cell("WK_CNPJTRA"):SetValue(TRBSF2->A2_CGC) // CNPJ Transportador 
      _oSect1_A:Cell("TA2_EST"):SetValue(TRBSF2->A2_EST)    // UF Transportador
      _oSect1_A:Cell("TA2_MUN"):SetValue(TRBSF2->A2_MUN)    // Municipio Trans portador 


      _nQtdePallets := 0
      _cLocal       := ""

      If MV_PAR03 = "1" .Or. MV_PAR07 = "2"
         If SD2->(DBSeek(TRBSF2->F2_FILIAL+TRBSF2->F2_DOC+TRBSF2->F2_SERIE+TRBSF2->F2_CLIENTE+TRBSF2->F2_LOJA))
	         While !SD2->(Eof()) .And. (SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == TRBSF2->F2_FILIAL+TRBSF2->F2_DOC+TRBSF2->F2_SERIE+TRBSF2->F2_CLIENTE+TRBSF2->F2_LOJA )
               
               If MV_PAR03 = "1"
                  SB1->(DBSeek(xFilial("SB1")+SD2->D2_COD))
                  
                  _nQtde := SD2->D2_QUANT 
                  
                  _nQtPallet := 0

                  //================================================================================
                  // Cálculo da quantidade de Pallets
                  //================================================================================
                  If SB1->B1_I_UMPAL == '1'
         
                     _nQtPallet	:= Int( _nQtde / SB1->B1_I_CXPAL )
                     If Mod( _nQtde , SB1->B1_I_CXPAL ) <> 0 
                        _nQtPallet += 1
                     EndIf 

                  ElseIf SB1->B1_I_UMPAL == '2'
         
                     If SB1->B1_TIPCONV == 'D'
                        //_nQtde := _nQtde * SB1->B1_CONV
                        _nQtde := _nQtde / SB1->B1_CONV
                     ElseIf SB1->B1_TIPCONV == 'M'
                        //_nQtde := _nQtde / SB1->B1_CONV
                        _nQtde := _nQtde * SB1->B1_CONV
                     EndIf

                     _nQtPallet	:= Int( _nQtde / SB1->B1_I_CXPAL )
                     If Mod( _nQtde , SB1->B1_I_CXPAL ) <> 0 
                        _nQtPallet += 1
                     EndIf  
         
                  ElseIf SB1->B1_I_UMPAL == '3'
                     
                     _nQtde := _nQtde * SB1->B1_I_QT3UM
                     
                     If SB1->B1_TIPCONV == 'D'
                        //_nQtde := _nQtde * SB1->B1_CONV
                        _nQtde := _nQtde / SB1->B1_CONV
                     ElseIf SB1->B1_TIPCONV == 'M'
                        //_nQtde := _nQtde / SB1->B1_CONV
                        _nQtde := _nQtde * SB1->B1_CONV
                     EndIf

                     _nQtPallet	:= Int( _nQtde / SB1->B1_I_CXPAL )
                     If Mod( _nQtde , SB1->B1_I_CXPAL ) <> 0 
                        _nQtPallet += 1
                     EndIf
               
                  EndIf

                  _nQtdePallets += _nQtPallet
               EndIf

               If Subs(MV_PAR07,1,1) == "2"
                  If !(AllTrim(SD2->D2_LOCAL) $ _cLocal)
                     _cLocal += IIf(Empty(AllTrim(_cLocal)),"","; ") + AllTrim(SD2->D2_LOCAL)
                  EndIf
               EndIf

               SD2->(DBSkip())
            EndDo   

         EndIf
      EndIf
 
      _oSect1_A:Cell("WK_QTDPALL"):SetValue(_nQtdePallets)  // Quantidade Pallets
      _oSect1_A:Cell("C5_I_FILFT"):SetValue(_cFilFatur)           // Filial de Faturamento
      _oSect1_A:Cell("C5_I_PDFT") :SetValue(_cPedFatur)            // Pedido de Faturamento
      _oSect1_A:Cell("C5_I_PDPR") :SetValue(_cPedCarre)            // Pedido de Carregamento
      _oSect1_A:Cell("C5_CLIENTE"):SetValue(_cCliCarre)           // Cliente Carregamento
      _oSect1_A:Cell("WK_LOJCLIE"):SetValue(_cLojCarre)           // Loja Cliente Carregamento
      _oSect1_A:Cell("WK_NCLICAR"):SetValue(_cNomCarre)           // Nom3 Clien. Carregamento.
      _oSect1_A:Cell("WK_NFE")    :SetValue(_NfCarre)             // Nom3 Clien. Carregamento.
      _oSect1_A:Cell("F2_I_DENCL"):SetValue(TRBSF2->F2_I_DENCL)   // Data entrega Cliente
      _oSect1_A:Cell("F2_I_DENOL"):SetValue(TRBSF2->F2_I_DENOL)   // Data entrega Operador Logístico.
      _oSect1_A:Cell("F2_TPFRETE"):SetValue(TRBSF2->F2_TPFRETE)   // Tipo de Frete
      _oSect1_A:Cell("F2_CARGA")  :SetValue(TRBSF2->F2_CARGA)     // Tipo de Frete
      If Subs(MV_PAR07,1,1) == "2"
         _oSect1_A:Cell("D2_LOCAL")  :SetBlock({||_cLocal}) // Tipo de Frete
      EndIf
      _oSect1_A:Cell("F2_I_LOCEM"):SetValue(TRBSF2->F2_I_LOCEM)
      _oSect1_A:Cell("ZEL_DESCRI"):SetValue(TRBSF2->ZEL_DESCRI)
      _oSect1_A:Cell("F2_I_PENOL"):SetValue(TRBSF2->F2_I_PENOL)
      _oSect1_A:Cell("F2_I_PENCL"):SetValue(TRBSF2->F2_I_PENCL)
      _oSect1_A:Cell("F2_I_TT1TR"):SetValue(TRBSF2->F2_I_TT1TR)
      _oSect1_A:Cell("F2_I_TT2TR"):SetValue(TRBSF2->F2_I_TT2TR)
      _oSect1_A:Cell("F2_I_DTOP" ):SetValue(TRBSF2->F2_I_DTOP)

      If !Empty(TRBSF2->DAI_I_TIPC)
         cPTpcarga:=If(TRBSF2->DAI_I_TIPC="1","1-Pallet Chep",If(TRBSF2->DAI_I_TIPC="2","2-Estivada",If(TRBSF2->DAI_I_TIPC="3","3-Pallet PBR",If(TRBSF2->DAI_I_TIPC="4","4-Pallet Descartavel",If(TRBSF2->DAI_I_TIPC="5","5-Pallet Chep Retorno",If(TRBSF2->DAI_I_TIPC="6","6-Pallet PBR Retorno","            "))))))
      Else
         cPTpcarga:=If(TRBSF2->C5_I_TIPCA='1','1-Pallet Chep','2-Estivada')   
      EndIf 
      //_oSect1_A:Cell("WK_CNPJTRA"):SetValue(TRBSF2->CGC_OPER) // CNPJ Transportador 
      //_oSect1_A:Cell("TA2_EST")   :SetValue(TRBSF2->EST_OPER) // UF Transportador
      //_oSect1_A:Cell("TA2_MUN")   :SetValue(TRBSF2->MUN_OPER) // Municipio Trans portador 
      //_oSect1_A:Cell("E1_VENCREA" ):SetValue(_dDataVenctoSE1) 
      _oSect1_A:Cell("E1_VENCREA"):SetValue(SToD(TRBSF2->E1_VENCREA)) 
      _oSect1_A:Cell("C5_I_TIPCA"):SetValue(cPTpcarga)
      _oSect1_A:Cell("WK_CNPJOPL"):SetValue(TRBSF2->CGC_OPER)    // CNPJ Operador Logistico.
      _oSect1_A:Cell("WK_NOMEOPL"):SetValue(TRBSF2->NOME_OPER)   // Razão Social Operador Logítico
      _oSect1_A:Cell("WK_UFOPL"  ):SetValue(TRBSF2->EST_OPER)    // UF Operador Logistico
      _oSect1_A:Cell("WK_MUNOPL" ):SetValue(TRBSF2->MUN_OPER)    // Municipio Operador Logistico
      _oSect1_A:Cell("C5_I_AGEND"):SetValue(TRBSF2->C5_I_AGEND)
      _oSect1_A:PrintLine()
 
      _cFilFatur := ""
      _cPedFatur := ""
      _cFilcarre := ""
      _cPedCarre := "" 
      _cCliCarre := ""
      _cLojCarre := "" 
      _cNomCarre := "" 
      _NfCarre   := ""
       
 	   TRBSF2->(DBSkip())
       
   EndDo     
   //====================================================================================================
   // Finaliza segunda seção.
   //====================================================================================================	
   _oSect1_A:Finish()
    
End Sequence

SE1->(DBSetOrder(1))

Return

