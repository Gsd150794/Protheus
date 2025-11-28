/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: REST023 // U_REST023
Autor-----------: Igor Melgaço
Data da Criacao-: 07/03/2023   
Descrição-------: Chamado 43157 - ANDRE. Relação de Produtos e seu ultimo custo. 
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function REST023()

Local _aParAux  := {} , nI
Local _aParRet  := {}

MV_PAR01 := Space(200)
MV_PAR02 := Space(200)
MV_PAR03 := Space(200)
MV_PAR04 := Space(200)
MV_PAR05 := Space(4)

_aItalac_F3 := {}

_BSelectSB1:={|| "SELECT DISTINCT B1_GRUPO FROM "+RETSQLNAME("SB1")+" SB1 WHERE"+;
				 " SB1.B1_GRUPO  <> ' '  AND "+;	
				 " D_E_L_E_T_ = ' ' ORDER BY B1_GRUPO " }

//Italac_F3:={}         1           2         3                                   4                                                                                        5            6             7             8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave                         , _nCpoDesc                                                                              ,_bCondTab , _cTitAux, _nTamChv            , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR02"   ,_BSelectSB1,{|Tab| (Tab)->B1_GRUPO },{|Tab| AllTrim(Posicione("SBM",1,xFilial("SBM")+(Tab)->B1_GRUPO,"BM_DESC")) },          ,"Grupos"  , Len(SB1->B1_GRUPO),          ,           ,.F.       ,       , } )

_BSelectSB1:={|| "SELECT DISTINCT B1_TIPO FROM "+RETSQLNAME("SB1")+" SB1 WHERE"+;
				 " SB1.B1_TIPO  <>  ' ' AND "+;	
				 " D_E_L_E_T_ = ' ' ORDER BY B1_TIPO " }

//Italac_F3:={}         1           2         3                                   4                                                                                        5            6             7             8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave                         , _nCpoDesc                                                                              ,_bCondTab , _cTitAux, _nTamChv            , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR03"   ,_BSelectSB1,{|Tab| (Tab)->B1_TIPO },{|Tab| AllTrim(Posicione("SX5",1,xFilial("SX5")+"02"+AllTrim((Tab)->B1_TIPO),"X5_DESCRI")) },          ,"Grupos"  , Len(SB1->B1_TIPO),          ,           ,.F.       ,       , } )

//_cSelSA2:="SELECT DISTINCT A2_COD,A2_NREDUZ FROM "+RETSQLNAME("SA2")+" SA2 WHERE D_E_L_E_T_ = ' ' AND SubStr(A2_COD,1,1) = 'F' AND A2_COD <> 'F00001'  ORDER BY A2_COD "
_cSelSA2:="SELECT A2_COD, A2_LOJA, A2_NREDUZ FROM SA2010 WHERE D_E_L_E_T_ = ' ' AND A2_COD||A2_LOJA IN ( "
_cSelSA2+="       SELECT T.A2_COD||T.A2_LOJA  FROM("
_cSelSA2+="              SELECT A2_COD, MIN(A2_LOJA) A2_LOJA FROM SIGA.SA2010 "
_cSelSA2+="                     WHERE D_E_L_E_T_ = ' ' AND SubStr(A2_COD,1,1) = 'F' AND A2_COD <> 'F00001' GROUP BY A2_COD) T) ORDER BY A2_COD "
//Italac_F3:={}         1           2         3                                   4             5            6             7         8             9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave                         , _nCpoDesc     ,_bCondTab , _cTitAux      , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR04"   ,_cSelSA2,{|Tab|(Tab)->A2_COD},{|Tab| (Tab)->A2_NREDUZ}, ,"Fornecedores" ,          ,          ,20        ,.F.        ,       , } )

aAdd( _aParAux , { 1 , "Filial"             , MV_PAR01, "@!"  , ""  ,"LSTFIL", "" , 060 , .F. } ) 
aAdd( _aParAux , { 1 , "Grupo de Produto"  	, MV_PAR02, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Tipo de Produto"   	, MV_PAR03, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Fornecedor"	  		, MV_PAR04, "@!"  , ""	,'F3ITLC', "" , 100 , .F. } )
aAdd( _aParAux , { 3 , "Considera Produto Bloqueado"	, MV_PAR05, { "Sim" , "Nao"  }		, 50 , ""	, .F. } )

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next 

While ParamBox( _aParAux , "SELECIONE OS FILTROS" , _aParRet , {|| .T. } , , , , , , , .T. , .T. )
	FWMsgRun(,{|oproc|  REST023PROC(oProc) },'Aguarde processamento...','Lendo dados...')
EndDo

Return

/*
===============================================================================================================================
Programa--------: REST023PROC 
Autor-----------: Igor Melgaço
Data da Criacao-: 11/08/2022   
Descrição-------: Rotina de Processamento da Listagem. 
Parametros------: oProc = Objeto da regua de processamento
Retorno---------: NENHUM
===============================================================================================================================
*/
Static Function REST023PROC(oproc)
Local _aDados := {}
Local _aCab := {}

_aDados := REST023QRY(oproc)

If Len(_aDados) = 0 
    U_ITMsg("Não há dados no periodo.","Envio do E-MAIL",,3)
Else
	_cTitulo := "Relação de Produtos e seu ultimo valor de compra"

	aAdd(_aCab,"Filial")
	aAdd(_aCab,"Documento")
	aAdd(_aCab,"Emissao")
	aAdd(_aCab,"Data Digit.")
	aAdd(_aCab,"Cod Fornecedor")
	aAdd(_aCab,"Loja")
	aAdd(_aCab,"Nome")
	aAdd(_aCab,"Código")
	aAdd(_aCab,"Descricao")
	aAdd(_aCab,"Vr Unit")
	aAdd(_aCab,"Custo Unit")

						  //  , _aCols   ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca )
	U_ITListBox(_cTitulo,_aCab,_aDados   , .T.    , 1    ,        ,          ,        ,         ,     ,        ,          ,       ,         ,          ,            )
EndIf

Return 


/*
===============================================================================================================================
Programa--------: REST023QRY 
Autor-----------: Igor Melgaço
Data da Criacao-: 06/03/2023
Descrição-------: Processamento da Query 
Parametros------: oProc = Objeto da regua de processamento
Retorno---------: _aDados = Dados de retorno do processamento da query
===============================================================================================================================
*/
Static Function REST023QRY(oproc)
Local _cAliasQRY   := ''
Local _cFiltro	   := ''
Local _aDados      := {}
Local _nAtual := 0

_cAliasQRY := GetNextAlias()

_cFiltro += "% "
_cFiltro += " SF1.D_E_L_E_T_ = ' ' "
_cFiltro += " AND SF1.F1_STATUS = 'A'  "

If !Empty(AllTrim(MV_PAR01))
	_cFiltro += " AND SF1.F1_FILIAL IN " +FormatIn(AllTrim(MV_PAR01),";")
EndIf

If !Empty(AllTrim(MV_PAR02))
	_cFiltro += " AND SB1.B1_GRUPO IN " +FormatIn(AllTrim(MV_PAR02),";")
EndIf

If !Empty(AllTrim(MV_PAR03))
	_cFiltro += " AND SB1.B1_TIPO IN " +FormatIn(AllTrim(MV_PAR03),";")
EndIf

If !Empty(AllTrim(MV_PAR04))
	_cFiltro += " AND SF1.F1_FORNECE  IN "+FormatIn(AllTrim(MV_PAR04),";")
EndIf

If MV_PAR05 = 2
	_cFiltro += " AND SB1.B1_MSBLQL <> '1' "
EndIf

_cFiltro += " %"

BeginSql Alias _cAliasQRY

	SELECT SD1.D1_COD, B1_DESC, SF1.F1_FILIAL,SD1.D1_DOC, SF1.F1_EMISSAO, SF1.F1_DTDIGIT, SF1.F1_FORNECE, SF1.F1_LOJA, SA2.A2_NOME, SD1.D1_VUNIT, SD1.D1_CUSTO,SD1.D1_QUANT ,SD1.R_E_C_N_O_
	FROM %Table:SF1% SF1
		JOIN %Table:SD1% SD1 ON SF1.F1_FILIAL = SD1.D1_FILIAL AND SF1.F1_DOC = SD1.D1_DOC AND SF1.F1_SERIE = SD1.D1_SERIE AND SF1.F1_FORNECE = SD1.D1_FORNECE AND SF1.F1_LOJA = SD1.D1_LOJA AND SD1.D_E_L_E_T_ = ' '
		JOIN %Table:SA2% SA2 ON SF1.F1_FORNECE = SA2.A2_COD AND SF1.F1_LOJA = SA2.A2_LOJA  AND SA2.D_E_L_E_T_ = ' '
		JOIN %Table:SB1% SB1 ON SD1.D1_COD = SB1.B1_COD AND SB1.D_E_L_E_T_ = ' '
		JOIN (  SELECT SF1_3.F1_FILIAL,SD1_3.D1_COD,SF1_3.F1_EMISSAO, MAX(SD1_3.R_E_C_N_O_) AS R_E_C_N_O_
				FROM %Table:SF1% SF1_3
				JOIN %Table:SD1% SD1_3 ON SF1_3.F1_FILIAL = SD1_3.D1_FILIAL AND SF1_3.F1_DOC = SD1_3.D1_DOC AND SF1_3.F1_SERIE = SD1_3.D1_SERIE AND SF1_3.F1_FORNECE = SD1_3.D1_FORNECE AND SF1_3.F1_LOJA = SD1_3.D1_LOJA AND SD1_3.D_E_L_E_T_ = ' '
				JOIN %Table:SF4% SF4_3 ON SF4_3.F4_FILIAL = SD1_3.D1_FILIAL AND SF4_3.F4_CODIGO = SD1_3.D1_TES AND SF4_3.D_E_L_E_T_ = ' '
				JOIN ( SELECT SF1_2.F1_FILIAL, SD1_2.D1_COD, MAX(SF1_2.F1_EMISSAO) AS ULTEMIS
						FROM %Table:SF1% SF1_2
						JOIN %Table:SD1% SD1_2 ON SF1_2.F1_FILIAL = SD1_2.D1_FILIAL AND SF1_2.F1_DOC = SD1_2.D1_DOC AND SF1_2.F1_SERIE = SD1_2.D1_SERIE AND SF1_2.F1_FORNECE = SD1_2.D1_FORNECE AND SF1_2.F1_LOJA = SD1_2.D1_LOJA AND SD1_2.D_E_L_E_T_ = ' '
						JOIN %Table:SF4% SF4_2 ON SF4_2.F4_FILIAL = SD1_2.D1_FILIAL AND SF4_2.F4_CODIGO = SD1_2.D1_TES AND SF4_2.D_E_L_E_T_ = ' '
						WHERE SF1_2.D_E_L_E_T_ = ' '
							AND SF1_2.F1_STATUS = 'A' 
							AND SD1_2.D1_QUANT > 0 
							AND SD1_2.D1_TIPO = 'N'
							AND SF4_2.F4_ESTOQUE = 'S'	
						GROUP BY SF1_2.F1_FILIAL, SD1_2.D1_COD) QRY ON SF1_3.F1_FILIAL = QRY.F1_FILIAL AND SD1_3.D1_COD = QRY.D1_COD AND SF1_3.F1_EMISSAO = QRY.ULTEMIS   
				WHERE SF1_3.D_E_L_E_T_ = ' '
					AND SF1_3.F1_STATUS = 'A'
					AND SD1_3.D1_QUANT > 0 
					AND SD1_3.D1_TIPO = 'N'
					AND SF4_3.F4_ESTOQUE = 'S'	
				GROUP BY SF1_3.F1_FILIAL, SD1_3.D1_COD, SF1_3.F1_EMISSAO) QRY2 ON QRY2.R_E_C_N_O_ = SD1.R_E_C_N_O_   
	WHERE %Exp:_cFiltro%

EndSql

DBSelectArea(_cAliasQRY)
(_cAliasQRY)->(DBGoTop())
If !(_cAliasQRY)->(Eof())
	nTotal := (_cAliasQRY)->(FCount())
	ProcRegua(nTotal)
	While !(_cAliasQRY)->(Eof())
		_nAtual++
		aAdd(_aDados,{	(_cAliasQRY)->F1_FILIAL,;
						(_cAliasQRY)->D1_DOC,;
						DToC(SToD((_cAliasQRY)->F1_EMISSAO)),;
						DToC(SToD((_cAliasQRY)->F1_DTDIGIT)),;
						(_cAliasQRY)->F1_FORNECE,;
						(_cAliasQRY)->F1_LOJA,;
						(_cAliasQRY)->A2_NOME,;
                        (_cAliasQRY)->D1_COD,;
						(_cAliasQRY)->B1_DESC,;						
						Transform( (_cAliasQRY)->D1_VUNIT ,"@E 9,999,999,999.99999"),;
						Transform( IIf((_cAliasQRY)->D1_QUANT>0,(_cAliasQRY)->D1_CUSTO/(_cAliasQRY)->D1_QUANT,0) ,"@E 9,999,999,999.99999")})

		(_cAliasQRY)->(DBSkip())
		
		oproc:cCaption := ("Processando " + cValToChar(_nAtual) + " de " + cValToChar(nTotal) + "...")
		ProcessMessages()
	EndDo
	(_cAliasQRY)->( DBCloseArea() )
EndIf

Return _aDados
