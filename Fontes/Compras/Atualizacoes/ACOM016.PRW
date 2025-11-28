/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |27/05/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Julio Paz     |29/09/2024| Chamado 48652. Alterar campo de validação de usuário Italac na query de filtro, da eliminação de resíduo.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWBROWSE.CH"
#Include 'FWMVCDef.ch'

Static _cAliasMrk	:= ""

/*
===============================================================================================================================
Programa----------: ACOM016
Autor-------------: Josué Danich Prestes
Data da Criacao---: 28/12/2015
Descrição---------: Elimina resíduos de SC e Pedido de Compras
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM016()

Local _aAlias		:= {} As Array
Local _aColumns		:= {} As Array
Local _cFilSalva    := cFilAnt As Character
Private aRotina		:= Menudef() As Array
Private _aRegsSC1	:= {} As Array
Private _aRegsSC7	:= {} As Array
Private _aRegsAll	:= {} As Array
Private _cPerg		:= "ACOM016" As Character
Private _bChkMarca	:= Nil As Codeblock
Private _bSelMarca	:= Nil As Codeblock
Private _bAllMarca	:= Nil As Codeblock
Private _dEmissIni	:= "" As Character
Private _dEmissFim	:= "" As Character
Private _cSolicIni	:= "" As Character
Private _cSolicFim	:= "" As Character
Private _cProDe		:= "" As Character
Private _cProAte	:= "" As Character

_cPerg := PadR( _cPerg , 10 , " " ) 

_cFilSel:=cFilAnt:=_cFilSalva//POR CAUSA DO Loop
If !Pergunte(_cPerg,.T.)
	Return .F.
EndIf

If MV_PAR01 = 2
	_cFilSel:=FWPesqSM0()
	If Empty(_cFilSel) 
		Return .F.
	EndIf
EndIf
cFilAnt:=_cFilSel

//======================================================================
// Inicializando variáveis com os parametros do pergunte. 
//======================================================================
_dEmissIni		:= MV_PAR02
_dEmissFim		:= MV_PAR03
_cSolicIni		:= MV_PAR04
_cSolicFim		:= MV_PAR05
_cProDe		    := MV_PAR06
_cProAte		:= MV_PAR07

//==================================================================
//Carrega blocos de código para o browse
//==================================================================

If MV_PAR08 == 2 //Solicitação de compra
	_bChkMarca	:= {|| IIf( aScan( _aRegsSC1 , { |x| x[1] + x[2] + x[3] == (_cAliasMrk)->C1_FILIAL + (_cAliasMrk)->C1_NUM + (_cAliasMrk)->C1_ITEM  } ) == 0 , 'LBNO' , 'LBOK' ) }
	_bSelMarca	:= {|| ( IIf( ( nPos := aScan( _aRegsSC1 , { |x| x[1] + x[2] + x[3] == (_cAliasMrk)->C1_FILIAL + (_cAliasMrk)->C1_NUM + (_cAliasMrk)->C1_ITEM } ) ) == 0 ,;
							 ( aAdd( _aRegsSC1 , { (_cAliasMrk)->C1_FILIAL, (_cAliasMrk)->C1_NUM, (_cAliasMrk)->C1_ITEM }  ) , lMarcou := .T. ) , ;
							 ( aDel( _aRegsSC1 , nPos ) , aSize( _aRegsSC1 , Len( _aRegsSC1 ) -1 ) ) ) ) }
	_bAllMarca	:= {|| IIf( Empty( _aRegsSC1 ) , _aRegsSC1 := aClone( _aRegsAll ) , _aRegsSC1 := {} ) , oMrkBrowse:Refresh() , oMrkBrowse:GoTop() }
ElseIf MV_PAR08 == 1 //Pedido de compra
	_bChkMarca	:= {|| IIf( aScan( _aRegsSC7 , { |x| x[1] + x[2] + x[3] == (_cAliasMrk)->C7_FILIAL + (_cAliasMrk)->C7_NUM + (_cAliasMrk)->C7_ITEM  } ) == 0 , 'LBNO' , 'LBOK' ) }
	_bSelMarca	:= {|| ( IIf( ( nPos := aScan( _aRegsSC7 , { |x| x[1] + x[2] + x[3] == (_cAliasMrk)->C7_FILIAL + (_cAliasMrk)->C7_NUM + (_cAliasMrk)->C7_ITEM } ) ) == 0 ,;
							 ( aAdd( _aRegsSC7 , { (_cAliasMrk)->C7_FILIAL, (_cAliasMrk)->C7_NUM, (_cAliasMrk)->C7_ITEM }  ) , lMarcou := .T. ) , ;
							 ( aDel( _aRegsSC7 , nPos ) , aSize( _aRegsSC7 , Len( _aRegsSC7 ) -1 ) ) ) ) }
	_bAllMarca	:= {|| IIf( Empty( _aRegsSC7 ) , _aRegsSC7 := aClone( _aRegsAll ) , _aRegsSC7 := {} ) , oMrkBrowse:Refresh() , oMrkBrowse:GoTop() }
EndIf

//--------------------------------------------------------
//Retorna as colunas para o preenchimento da FWMarkBrowse
//--------------------------------------------------------
FWMsgRun( ,{|| _aAlias := ACOM016QRY() } , 'Aguarde!' , 'Verificando os registros...' )
	
_cAliasMrk	:= _aAlias[1]
_aColumns 	:= _aAlias[2]

If !(_cAliasMrk)->(Eof())
	//----------------------
	//Criação da MarkBrowse
	//----------------------
	oMrkBrowse:= FWMarkBrowse():New()
	oMrkBrowse:SetDataTable(.T.)
	oMrkBrowse:SetAlias(_cAliasMrk)
	oMrkBrowse:AddMarkColumns( _bChkMarca , _bSelMarca , _bAllMarca )
	oMrkBrowse:SetDescription("")
	oMrkBrowse:SetColumns(_aColumns)
	oMrkBrowse:Activate()
Else
	FWAlertInfo("Não existem registros de acordo com os filtros selecionados! Modifique os filtros e tente novamente","ACOM01601")
EndIf

If !Empty (_cAliasMrk)
	(_cAliasMrk)->(DBCloseArea())
	Ferase(_cAliasMrk+GetDBExtension())
	Ferase(_cAliasMrk+OrdBagExt())
	_cAliasMrk := ""
	
	If MV_PAR08 == 2 //Solicitação de compra
		DBSelectArea("SC1")
		SC1->(DBSetOrder(1))
	ElseIf MV_PAR08 == 1 //Pedido de compra
		DBSelectArea("SC7")
		SC7->(DBSetOrder(1))
	EndIf
EndIf

cFilAnt:=_cFilSalva

Return (.T.)

/*
===============================================================================================================================
Programa----------: ACOM016QRY
Autor-------------: Josué Danich Prestes
Data da Criacao---: 28/12/2015
Descrição---------: Função utilizada para montar a query e arquivo temporário
Parametros--------: Nenhum
Retorno-----------: Array [1] - Tabela temporária / [2] - Colunas do browse
===============================================================================================================================
*/
Static Function ACOM016QRY()

Local _cAliasTrb	:= GetNextAlias() As Character
Local _aFields		:= {} As Array
Local _cSelect		:= "" As Character
Local _aStructSC1	:= {} As Array
Local _aColumns		:= {} As Array
Local _nX			:= 0 As Numeric
Local _xValid		:= Nil As Variant
Local _nk			:= 0 As Numeric
Local _nI			:= 0 As Numeric
//Variaveis utilizadas para montar o where da query, referente aos filtros preenchidos pelo usuario.
Local _cWFilial	 	:= "" As Character
Local _cWhere	 	:= "" As Character
Local _cTipoAdmR 	:= "" As Character
Local _cSuprLeit 	:= SuperGetMV("IT_TPPRDPC",.F.,"MP;PP;PI;SP") As Character

Private _cTempTab	:= "" As Character

ProcRegua(0)
IncProc('Inicializando a rotina...')

If MV_PAR08 == 2 //Solicitação de compra
	_aFields		:= {	'C1_FILIAL',;
							'C1_EMISSAO',;
							'C1_NUM',;
							'C1_CODCOMP',;
							'C1_I_CODAP',;
							'C1_USER',;
							'C1_SOLICIT',;
							'C1_FORNECE',;
							'C1_DATPRF',;
							'C1_PRODUTO',;
							'C1_DESCRI',;
							'B1_I_DESCD',;
							'C1_UM',;
							'C1_QUANT',;
							'C1_QUJE',;
							'C1_I_ULTPR',;
							'C1_I_ULTDT',;
							'C1_I_URGEN',;
							'C1_I_APLIC',;
							'C1_I_CDINV',;
							'ZZI_DESINV',;
							'C1_CC',;
                            'C1_USER',; 					
							'C1_I_DTRET'}
						
	_aStructSC1	:= SC1->(DBSTRUCT())
	
	For _nX := 1 To Len(_aFields)
		_cSelect += _aFields[_nX] + ", "
	Next _nX

	//======================================
	//Tratamento da clausula where da filial
	//======================================
	_cWFilial := "%"
	_cWFilial += " SC1.C1_FILIAL  = '" + xFilial("SC1") + "' "
	_cWFilial += "%"

	_cWhere := "%"
	_cWhere += " SC1.C1_PRODUTO BETWEEN '" + _cProDe + "' AND '" + _cProAte + "' AND "
	_cWhere += " (SC1.C1_QUANT - SC1.C1_QUJE) <= (SC1.C1_QUANT * " + AllTrim(Str(MV_PAR13/100)) + ")  AND "
	_cWhere += " (SC1.C1_COTACAO < '1' OR SC1.C1_COTACAO = 'XXXXXX') AND "   //Cotação não realizada ou realizado pedido direto que atualiza a C1_QUJE
	_cWhere += " SC1.C1_RESIDUO <> 'S' AND"
	_cWhere += " SC1.C1_QUJE < SC1.C1_QUANT"
	
	_cTipoAdmR := U_ITACSUSR( 'ZZL_TPADMR')
    
	_xValid := U_ITACSUSR( 'ZZL_ADMSC' , 'S' )

	If (ValType(_xValid) == 'L' .And. !_xValid) .Or. ValType(_xValid) <> 'L'
       _cWhere += " AND (SC1.C1_I_CDSOL = '" + AllTrim(__cUserId) + "' OR SC1.C1_I_CODAP = '" + AllTrim(__cUserId) + "') " 
	ElseIf (ValType(_xValid) == 'L' .And. _xValid)  
	   If _cTipoAdmR == "2"     
          _cWhere += " AND (SC1.C1_I_CDSOL = '" + AllTrim(__cUserId) + "' OR SC1.C1_I_CODAP = '" + AllTrim(__cUserId) + "' OR B1_TIPO IN " + FormatIn(_cSuprLeit,";") + ") " // - Suprimento do Leite (elimina resíduo de suprimento do leite)
       ElseIf _cTipoAdmR == "1" 
          _cWhere += " AND (SC1.C1_I_CDSOL = '" + AllTrim(__cUserId) + "' OR SC1.C1_I_CODAP = '" + AllTrim(__cUserId) + "' OR B1_TIPO NOT IN " + FormatIn(_cSuprLeit,";") + ") " // Compras (elimina resíduo de compras)
       EndIf
	EndIf	
	
	_cWhere += "%"
	
	BeginSql alias _cAliasTrb

	SELECT ' ' SC1_OK,
			C1_FILIAL,
			C1_EMISSAO, 
			C1_NUM, 
			C1_ITEM, 
			C1_CODCOMP, 
			Y1_NOME,
	 		C1_I_CODAP, 
	 		ZZ7_NOME, 
	 		C1_PRODUTO, 
	 		C1_DESCRI, 
	 		C1_UM, 
	 		C1_QUANT, 
	 		C1_QUJE,
	 		C1_FORNECE,
	 		C1_LOJA,
	 		C1_SOLICIT,
	 		C1_USER, 
	 		C1_I_ULTPR,
	  		C1_I_ULTDT, 
	  		C1_I_URGEN, 
	  		C1_I_APLIC, 
	  		C1_I_CDINV, 
	  		ZZI_DESINV,
	  		C1_DATPRF, 
	  		C1_CC, 
	  		C1_I_DTRET,
	   		C1_DATPRF, 
	   		C1_OBS, 
	   		B1_I_DESCD, 
	   		C1_I_NOME,
            C1_USER,    
	   		SC1.R_E_C_N_O_ SC1RECNO  
	
	FROM %Table:SC1% SC1
	
	LEFT JOIN %Table:SY1% SY1 ON SY1.Y1_FILIAL = %xFilial:SY1% AND SC1.C1_CODCOMP = SY1.Y1_COD AND SY1.%notDel%
	LEFT JOIN %Table:ZZ7% ZZ7 ON SC1.C1_FILIAL = ZZ7.ZZ7_FILIAL AND SC1.C1_I_CODAP = ZZ7.ZZ7_CODUSR AND ZZ7.%notDel%
	LEFT JOIN %Table:ZZI% ZZI ON SC1.C1_FILIAL = ZZI.ZZI_FILIAL AND SC1.C1_I_CDINV = ZZI.ZZI_CODINV AND ZZI.%notDel%
	LEFT JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1% AND SB1.B1_COD = SC1.C1_PRODUTO AND SB1.%notDel%
	
	WHERE
	
	%Exp:_cWFilial% AND
	SC1.C1_NUM BETWEEN %exp:_cSolicIni%		AND %exp:_cSolicFim%	AND
	SC1.C1_EMISSAO BETWEEN %exp:_dEmissIni%	AND %exp:_dEmissFim%	AND	
	SC1.C1_DATPRF  BETWEEN %exp:MV_PAR11%	AND %exp:MV_PAR12%	AND	
	SC1.C1_FORNECE BETWEEN %exp:MV_PAR09%	AND %exp:MV_PAR10%	AND	
	SC1.C1_QUANT > 0 AND
	%Exp:_cWhere%	AND
	SC1.%notDel%

	ORDER BY
	
	C1_FILIAL, 
	C1_EMISSAO, 
	C1_NUM, 
	C1_ITEM 

	EndSql
	
					
ElseIf MV_PAR08 == 1 //Pedido de compra

	_aFields		:= {	'C7_FILIAL',;
							'C7_EMISSAO',;
							'C7_NUM',;
							'C7_PRODUTO',;
							'C7_DESCRI',;
							'C7_UM',;
							'C7_QUANT',;
							'C7_QUJE',;
							'C7_PRECO',;
							'C7_TOTAL',;
							'C7_USER',;
							'C7_GRUPCOM',;
							'C7_FORNECE',;
							'C7_I_NFORN',;
							'C7_DATPRF',;
							'C7_I_URGEN',;
							'C7_I_APLIC',;
							'C7_I_CDINV',;
							'C7_COMPRA',;
							'ZZI_DESINV',;
                            'C7_USER',; 
							'C7_I_CMPDI'}
						
	_aStructSC1	:= SC7->(DBSTRUCT())

	For _nX := 1 To Len(_aFields)
		_cSelect += _aFields[_nX] + ", "
	Next _nX

	//======================================
	//Tratamento da clausula where da filial
	//======================================
	_cWFilial := "%"
	_cWFilial += " SC7.C7_FILIAL  = '" + xFilial("SC7") + "' "
	_cWFilial += "%"

	_cWhere := "%"
	_cWhere += " SC7.C7_PRODUTO BETWEEN '" + _cProDe + "' AND '" + _cProAte + "' AND "
	_cWhere += " (SC7.C7_QUANT - (SC7.C7_QUJE + (Case when SC7.C7_QTDACLA > 0 then SC7.C7_QTDACLA Else 0 end ))) <= (SC7.C7_QUANT * " + AllTrim(Str(MV_PAR13/100)) + ")  AND "
	_cWhere += " SC7.C7_ENCER <> 'S' AND "
	_cWhere += " SC7.C7_RESIDUO <> 'S' AND"
	
	//Se não é administrador de PC traz só PCs em que o usuário é comprador ou pertence ao Grupo de Compras do PC
	_xValid := U_ITACSUSR( 'ZZL_ADMPC' , 'S' ) // _xValid := U_ITACSUSR( 'ZZL_ADMSC' , 'S' )
	
	_cTipoAdmR := U_ITACSUSR( 'ZZL_TPADMR')
    
	If (ValType(_xValid) == 'L' .And. !_xValid) .Or. ValType(_xValid) <> 'L'
       _cWhere += " ( SC7.C7_USER = '" + AllTrim(__cUserId) + "' or  SAJ.AJ_GRCOM = C7_GRUPCOM ) AND " 
    ElseIf (ValType(_xValid) == 'L' .And. _xValid) .Or. ValType(_xValid) <> 'L'
	   If _cTipoAdmR == "2"  
          _cWhere += " ( SC7.C7_USER = '" + AllTrim(__cUserId) + "' or  SAJ.AJ_GRCOM = C7_GRUPCOM OR B1_TIPO IN " + FormatIn(_cSuprLeit,";") + ") AND " // - Suprimento do Leite (elimina resíduo de suprimento do leite)
       ElseIf _cTipoAdmR == "1" 
          _cWhere += " ( SC7.C7_USER = '" + AllTrim(__cUserId) + "' or  SAJ.AJ_GRCOM = C7_GRUPCOM OR B1_TIPO NOT IN " + FormatIn(_cSuprLeit,";") + ") AND " // Compras (elimina resíduo de compras)
	   EndIf
	EndIf	
	
	_cWhere += " SC7.C7_QTDACLA <= 0 AND"
	_cWhere += " SC7.C7_QUJE < SC7.C7_QUANT"
	_cWhere += "%"
	
	BeginSql alias _cAliasTrb

	SELECT ' ' SC7_OK,
			C7_FILIAL, 
			C7_EMISSAO, 
			C7_FORNECE, 
			C7_NUM, 
			C7_ITEM, 
			C7_PRODUTO,
			C7_DESCRI, 
			C7_UM, 
			C7_QUANT, 
			C7_PRECO, 
			C7_TOTAL, 
			C7_I_URGEN, 
			C7_DATPRF,  
			C7_CC, 
			C7_OBS,
	 		B1_I_DESCD, 
	 		SC7.R_E_C_N_O_ SC7RECNO, 
	 		C7_QUJE, C7_USER, 
	 		C7_GRUPCOM, 
	 		C7_FORNECE, 
	 		C7_LOJA, 
	 		C7_I_NFORN,
	 		C7_I_APLIC, 
	 		C7_I_CDINV, 
	 		ZZI_DESINV, 
	 		C7_I_CMPDI,  
			C7_COMPRA,;                               
	 		Y1_NOME,
	 		Y1_COD,
            C7_USER, 
	 		SC7.R_E_C_N_O_ SC7RECNO  
		
	FROM %Table:SC7% SC7
	
	LEFT JOIN %Table:SY1% SY1 ON SY1.Y1_FILIAL = %xFilial:SY1% AND SC7.C7_USER = SY1.Y1_USER AND SY1.%notDel%
	LEFT JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1% AND SB1.B1_COD = SC7.C7_PRODUTO AND SB1.%notDel%
	LEFT JOIN %Table:ZZI% ZZI ON ZZI.ZZI_FILIAL = %xFilial:ZZI% AND ZZI.ZZI_CODINV = SC7.C7_I_CDINV AND ZZI.%notDel%
	LEFT JOIN %Table:SAJ% SAJ ON SAJ.AJ_FILIAL = %xFilial:SAJ% AND SAJ.AJ_GRCOM = SC7.C7_GRUPCOM AND SAJ.AJ_USER = %exp:__cUserId% AND SAJ.%notDel%	
	
	WHERE
	
	%Exp:_cWFilial% AND
	SC7.C7_NUM BETWEEN %exp:_cSolicIni%		AND %exp:_cSolicFim%	AND
	SC7.C7_EMISSAO BETWEEN %exp:_dEmissIni%	AND %exp:_dEmissFim%	AND	
	SC7.C7_DATPRF  BETWEEN %exp:MV_PAR11%	AND %exp:MV_PAR12%	AND	
	SC7.C7_FORNECE BETWEEN %exp:MV_PAR09%	AND %exp:MV_PAR10%	AND	
	%Exp:_cWhere%	AND
	SC7.%notDel%

	ORDER BY
	
	C7_FILIAL, C7_EMISSAO, C7_NUM, C7_ITEM

	EndSql
	
EndIf

//----------------------------------------------------------------------
// Cria arquivo de dados temporário
//----------------------------------------------------------------------
_cTempTab := getnextalias()

_aStructSC1 := (_cAliasTrb)->(DbStruct())

//Ajusta numericos para não dar problema de tamanho
For _nk := 1 to Len(_aStructSC1)
	If _aStructSC1[_nk][2] == "N"
		_aStructSC1[_nk][3] := 18
		_aStructSC1[_nk][4] := 6
	EndIf
Next _nk

_oTemp := FWTemporaryTable():New( _cTempTab,  _aStructSC1 )
_oTemp:Create()

IncProc('Lendo os dados...')

While ! (_cAliasTrb)->(Eof())

   (_cTempTab)->(RecLock(_cTempTab,.T.))
   
   For _nI := 1 To Len(_aStructSC1)
       _cNomeCampo := AllTrim((_cAliasTrb)->(FieldName(_nI)))  
       _cCmpTemp := _cTempTab  + "->" + _cNomeCampo 
       _cCmpSC7  := _cAliasTrb + "->" + _cNomeCampo 
       &(_cCmpTemp) := &(_cCmpSC7)
   Next _nI
   
   (_cTempTab)->(MSUnLock())
   (_cAliasTrb)->(DBSkip())
EndDo

If MV_PAR08 == 2 //Solicitação de compra
	(_cTempTab)->( DBGoTop() )
	While (_cTempTab)->(!Eof())
		aAdd( _aRegsAll , { (_cTempTab)->C1_FILIAL, (_cTempTab)->C1_NUM, (_cTempTab)->C1_ITEM } )
		//Bloqueia SC1 para não haver alterações com essa tela aberta
		SC1->(DBGoTo((_cTempTab)->SC1RECNO))
		SC1->(MSUnLock())	
		SC1->(RecLock("SC1",.F.))
	
		(_cTempTab)->( DBSkip() )
	EndDo

	(_cTempTab)->( DBGoTop() )

	For _nX := 1 To Len(_aFields)
		If	!_aFields[_nX] == "SC1_OK" .And. _aFields[_nX] $ _cSelect
			aAdd(_aColumns,FWBrwColumn():New())
			_aColumns[Len(_aColumns)]:SetTitle(RetTitle(_aFields[_nX])) 
			_aColumns[Len(_aColumns)]:SetSize(TamSX3(_aFields[_nX])[1]) 
			_aColumns[Len(_aColumns)]:SetDecimal(TamSX3(_aFields[_nX])[2])

			If _aFields[_nX] == "C1_EMISSAO" .Or. _aFields[_nX] == "C1_I_ULTDT" .Or. _aFields[_nX] == "C1_I_DTRET"
				_aColumns[Len(_aColumns)]:SetData( &("{||SToD(" + _aFields[_nX] + ")}") )
			ElseIf _aFields[_nX] == "C1_FILIAL"
				_aColumns[Len(_aColumns)]:SetData( &("{||" + _aFields[_nX] + " + ' - ' + FWFilialName(cEmpAnt,C1_FILIAL) }") )
			ElseIf _aFields[_nX] == "C1_QUANT" .Or. _aFields[_nX] == "C1_I_ULTPR" .Or. _aFields[_nX] == "C1_QUJE"
				_aColumns[Len(_aColumns)]:SetData( &("{||" + _aFields[_nX] + "}") )
				_aColumns[Len(_aColumns)]:NALIGN := 2
			ElseIf _aFields[_nX] == "C1_USER"
				_aColumns[Len(_aColumns)]:SetData( &("{|| C1_USER + ' - ' + UsrFullName(C1_USER)}") )
				_aColumns[Len(_aColumns)]:SetSize(30) 
			ElseIf _aFields[_nX] == "C1_FORNECE"
				_aColumns[Len(_aColumns)]:SetData( &("{||C1_FORNECE + '/' + C1_LOJA + ' - '  + C1_I_NOME}") )
				_aColumns[Len(_aColumns)]:SetSize(30) 
			ElseIf _aFields[_nX] == "C1_NUM"
				_aColumns[Len(_aColumns)]:SetData( &("{||C1_NUM + ' / ' + C1_ITEM}") )
				_aColumns[Len(_aColumns)]:SetSize(10) 
			ElseIf _aFields[_nX] == "C1_CODCOMP"
				_aColumns[Len(_aColumns)]:SetData( &("{||C1_CODCOMP + ' - ' + Y1_NOME }") )
				_aColumns[Len(_aColumns)]:SetSize(30) 
			ElseIf _aFields[_nX] == "C1_I_CODAP"
				_aColumns[Len(_aColumns)]:SetData( &("{||C1_I_CODAP + ' - ' + ZZ7_NOME }") )
				_aColumns[Len(_aColumns)]:SetSize(30) 
			ElseIf _aFields[_nX] == "C1_DATPRF"
				_aColumns[Len(_aColumns)]:SetData( &("{||DToC(SToD(C1_DATPRF))}") )
				_aColumns[Len(_aColumns)]:SetSize(10) 
			Else 
				_aColumns[Len(_aColumns)]:SetData( &("{||" + _aFields[_nX] + "}") )
			EndIf

		
			If "Y1" $ _aFields[_nX]
				_aColumns[Len(_aColumns)]:SetPicture(PesqPict("SY1",_aFields[_nX]))
			ElseIf "ZZ7" $ _aFields[_nX]
				_aColumns[Len(_aColumns)]:SetPicture(PesqPict("ZZ7",_aFields[_nX]))
			ElseIf "ZZI" $ _aFields[_nX]
				_aColumns[Len(_aColumns)]:SetPicture(PesqPict("ZZI",_aFields[_nX]))
			Else
				_aColumns[Len(_aColumns)]:SetPicture(PesqPict("SC1",_aFields[_nX]))
			EndIf
		EndIf
	Next _nX

ElseIf MV_PAR08 == 1 //Pedido de compra

	(_cTempTab)->( DBGoTop() )
	While (_cTempTab)->(!Eof())
		aAdd( _aRegsAll , { (_cTempTab)->C7_FILIAL, (_cTempTab)->C7_NUM, (_cTempTab)->C7_ITEM } )
		//Bloqueia SC7 para não haver alterações com essa tela aberta
		SC7->(DBGoTo((_cTempTab)->SC7RECNO))
		SC7->(MSUnLock())	
		SC7->(RecLock("SC7",.F.))
		(_cTempTab)->( DBSkip() )
	EndDo

	(_cTempTab)->( DBGoTop() )

	For _nX := 1 To Len(_aFields)
		If	!_aFields[_nX] == "SC7_OK" .And. _aFields[_nX] $ _cSelect
			aAdd(_aColumns,FWBrwColumn():New())

			_aColumns[Len(_aColumns)]:SetTitle(RetTitle(_aFields[_nX])) 
			_aColumns[Len(_aColumns)]:SetSize(TamSX3(_aFields[_nX])[1]) 
			_aColumns[Len(_aColumns)]:SetDecimal(TamSX3(_aFields[_nX])[2])

			If _aFields[_nX] == "C7_EMISSAO" .Or. _aFields[_nX] == "C7_I_DATPRF" 
				_aColumns[Len(_aColumns)]:SetData( &("{||SToD(" + _aFields[_nX] + ")}") )
			ElseIf _aFields[_nX] == "C7_USER"
				_aColumns[Len(_aColumns)]:SetData( &("{||" + 'Y1_COD' + " + ' - ' + Y1_NOME }") )
				_aColumns[Len(_aColumns)]:SetTitle("Comprador") 
				_aColumns[Len(_aColumns)]:SetSize(40)
			ElseIf _aFields[_nX] == "C7_FILIAL"
				_aColumns[Len(_aColumns)]:SetData( &("{||" + _aFields[_nX] + " + ' - ' + FWFilialName(cEmpAnt,C7_FILIAL) }") )
			ElseIf _aFields[_nX] == "C7_QUANT" .Or. _aFields[_nX] == "C7_PRECO" .Or. _aFields[_nX] == "C7_TOTAL" .Or. _aFields[_nX] == "C7_QUJE"
				_aColumns[Len(_aColumns)]:SetData( &("{||" + _aFields[_nX] + "}") )
				_aColumns[Len(_aColumns)]:NALIGN := 2
			ElseIf _aFields[_nX] == "C7_NUM"
				_aColumns[Len(_aColumns)]:SetData( &("{||" + _aFields[_nX] + " + ' / ' + C7_ITEM  }") )
			ElseIf _aFields[_nX] == "C7_FORNECE"
				_aColumns[Len(_aColumns)]:SetData( &("{||" + _aFields[_nX] + " + ' / ' + C7_LOJA  }") )
			ElseIf _aFields[_nX] == "C7_DATPRF"
				_aColumns[Len(_aColumns)]:SetData( &("{||DToC(SToD(C7_DATPRF))}") )
				_aColumns[Len(_aColumns)]:SetSize(10) 
			Else
				_aColumns[Len(_aColumns)]:SetData( &("{||" + _aFields[_nX] + "}") )
			EndIf
	
			If "Y1" $ _aFields[_nX]
				_aColumns[Len(_aColumns)]:SetPicture(PesqPict("SY1",_aFields[_nX]))
			ElseIf "ZZ7" $ _aFields[_nX]
				_aColumns[Len(_aColumns)]:SetPicture(PesqPict("ZZ7",_aFields[_nX]))
			Else
				_aColumns[Len(_aColumns)]:SetPicture(PesqPict("SC7",_aFields[_nX]))
			EndIf
		EndIf
	Next _nX
EndIf

Return( { _cTempTab , _aColumns } )

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/07/2015
Descrição---------: Função utilizada para criação do menu
Parametros--------: Nenhum
Retorno-----------: aRotina - Opções de menu
===============================================================================================================================
*/
Static Function MenuDef()     

Local aRot := {} As Array

ADD OPTION aRot Title 'Eliminar Res.'			Action 'U_ACOM016E()'	OPERATION 2 ACCESS 0
ADD OPTION aRot Title 'Visualizar'				Action 'U_ACOM016V()'	OPERATION 2 ACCESS 0
ADD OPTION aRot Title 'Planilha'				Action 'U_ACOM016P()'	OPERATION 2 ACCESS 0

Return(Aclone(aRot))

/*
===============================================================================================================================
Programa----------: ACOM016V
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/07/2015
Descrição---------: Função utilizada para visualizar um única SC selecionada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM016V()

Local _aArea := FwGetArea() As Array

If MV_PAR08 == 2 //Solicitação de compra
	DBSelectArea("SC1")
	SC1->(DBSetOrder(1))
	SC1->(DBSeek(_aRegsAll[oMrkBrowse:OBROWSE:NAT][1] + _aRegsAll[oMrkBrowse:OBROWSE:NAT][2] + _aRegsAll[oMrkBrowse:OBROWSE:NAT][3]))
	A110Visual("SC1",SC1->(Recno()),2)	
ElseIf MV_PAR08 == 1 //Pedido de compra
	DBSelectArea("SC7")
	SC7->(DBSetOrder(1))
	SC7->(DBSeek(_aRegsAll[oMrkBrowse:OBROWSE:NAT][1] + _aRegsAll[oMrkBrowse:OBROWSE:NAT][2] + _aRegsAll[oMrkBrowse:OBROWSE:NAT][3]))
	Mata120(1,,,2,.T.)	
EndIf

FwRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: ACOM016P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/10/2015
Descrição---------: Função criada para gerar tela para exportação dos dados para planilha
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM016P()

Local _aArea	:= FWGetArea() As Array
Local aLogPla	:= {} As Array
Local nCont		:= 1 As Numeric
Local _bUserN	:= {|x| UsrFullName(x)} As Codeblock

If MV_PAR08 == 2 //Solicitação de compra
	aCampPla	:= {	'Índice',;
						'Filial',;
						'Dt Emissão',;
						'Núm.SC',;
						'Nome Comp.',;
						'Nome Aprov',;
						'Usuario',;
						'Solicit',;
						'Fornecedor',;
						'Dt Entrega',;
						'Produto',;
						'Descrição',;
						'Descri Det',;
						'Unid.Medida',;
						'Quantidade',;
						'Qtde Entregue',;
						'Último Preço',;
						'Ult.Compra',;
						'Urgente',;
						'Aplicação',;
						'Investimento',;
						'Desc.Invest.',;
						'Centro Custo',;
						'Data Retorno',;
						'Observação'}
						

	(_cAliasMrk)->(DBGoTop())

	While !(_cAliasMrk)->(Eof())
		aAdd( aLogPla , {	StrZero(nCont++,4),;																										//[1]Índice
						(_cAliasMrk)->C1_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,(_cAliasMrk)->C1_FILIAL,1)),;						//[2]Filial
						SToD((_cAliasMrk)->C1_EMISSAO),;																							//[3]Emissão
						(_cAliasMrk)->C1_NUM + " / " + (_cAliasMrk)->C1_ITEM,;																	//[4]SC		
						(_cAliasMrk)->C1_CODCOMP + " - " + (_cAliasMrk)->Y1_NOME,;										   						//[5]Comprador			
						(_cAliasMrk)->C1_I_CODAP + " - " + (_cAliasMrk)->ZZ7_NOME,;										  						//[6]Aprovador			
						(_cAliasMrk)->C1_USER + " - " + Eval(_bUserN,(_cAliasMrk)->C1_USER),;													//[7]Usuario
						(_cAliasMrk)->C1_SOLICIT,;	   																								//[7]Solicitante
						(_cAliasMrk)->C1_FORNECE + "/" + (_cAliasMrk)->C1_LOJA + " - " + (_cAliasMrk)->C1_I_NOME,; 						//[8] Fornecedor
						SToD((_cAliasMrk)->C1_DATPRF),;																								//[9] Data entrega
						(_cAliasMrk)->C1_PRODUTO,;																									//[10]Produto
						(_cAliasMrk)->C1_DESCRI,;																									//[11]Descrição
						(_cAliasMrk)->B1_I_DESCD,;																									//[12]Descrição Detalhada
						(_cAliasMrk)->C1_UM,;																										//[13]Unidade Medida
						AllTrim(Transform((_cAliasMrk)->C1_QUANT,PesqPict("SC1","C1_QUANT"))),;												//[14]Quantidade
						AllTrim(Transform((_cAliasMrk)->C1_QUJE,PesqPict("SC1","C1_QUJE"))),;													//[15]Quantidade ja entregue
						AllTrim(Transform((_cAliasMrk)->C1_I_ULTPR,PesqPict("SC1","C1_I_ULTPR"))),;											//[16]Último Preço
						SToD((_cAliasMrk)->C1_I_ULTDT),;											  												//[17]Última Compra
						(_cAliasMrk)->C1_I_URGEN,;												  													//[18]Urgente
						(_cAliasMrk)->C1_I_APLIC,;												  													//[19]Aplicação
						(_cAliasMrk)->C1_I_CDINV,;												 													//[20]Código Investimento
						(_cAliasMrk)->ZZI_DESINV,;												 													//[21]Descrição Investimento
						(_cAliasMrk)->C1_CC,;																										//[22]Centro de Custo
						SToD((_cAliasMrk)->C1_I_DTRET),;											  												//[23]Data Retorno
						(_cAliasMrk)->C1_OBS})															   											//[24]Observação
																				   									
		(_cAliasMrk)->(DBSkip())
	EndDo

	U_ITListBox( 'Geração Planilha' , aCampPla , aLogPla , .T. , 1 )

ElseIf MV_PAR08 == 1 //Pedido de compra
	aCampPla	:= {	'Índice',;
						'Filial',;
						'Dt Emissão',;
						'Núm.Pedido',;
						'Item',;
						'Produto',;
						'Descrição',;
						'Unid.Medida',;
						'Quantidade',;
						'Quant Ent.',;
						'Preço',;
						'Total',;
						'Comprador',;
						'Grp Compras',;
						'Fornecedor',;
						'Data Entrega',;
						'Urgente',;
						'Aplicacao',;
						'Invest',;
						'Compra Dir'}

	(_cAliasMrk)->(DBGoTop())

	While !(_cAliasMrk)->(Eof())
		aAdd( 			aLogPla , {	StrZero(nCont++,4),;																	//[01]Índice
						(_cAliasMrk)->C7_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,(_cAliasMrk)->C7_FILIAL,1)),;	//[02]Filial
						SToD((_cAliasMrk)->C7_EMISSAO),;																		//[03]Emissão
						(_cAliasMrk)->C7_NUM,;																				//[04]Número SC
						(_cAliasMrk)->C7_ITEM,;												 								//[05]Item
						(_cAliasMrk)->C7_PRODUTO,;																			//[06]Produto
						(_cAliasMrk)->C7_DESCRI,;																				//[07]Descrição
						(_cAliasMrk)->C7_UM,;																					//[08]Unidade Medida
						AllTrim(Transform((_cAliasMrk)->C7_QUANT,PesqPict("SC7","C7_QUANT"))),;						//[09]Quantidade
						AllTrim(Transform((_cAliasMrk)->C7_QUJE,PesqPict("SC7","C7_QUJE"))),;							//[10]Quant já entregue
						AllTrim(Transform((_cAliasMrk)->C7_PRECO,PesqPict("SC7","C7_PRECO"))),;						//[11]Preço Unit.
						AllTrim(Transform((_cAliasMrk)->C7_TOTAL,PesqPict("SC7","C7_TOTAL"))),;						//[12]Valor Total
						(_cAliasMrk)->Y1_COD + " - " + (_cAliasMrk)->Y1_NOME,;											//[13]Comprador
						(_cAliasMrk)->C7_GRUPCOM,;																			//[14]Grupo de compras
						(_cAliasMrk)->C7_FORNECE + "/" + (_cAliasMrk)->C7_LOJA + " - " + (_cAliasMrk)->C7_I_NFORN,;//[15] Fornecedor
						SToD((_cAliasMrk)->C7_DATPRF),;																		//[16] Data Entrega
						(_cAliasMrk)->C7_I_URGEN,;																			//[16]Urgente
						(_cAliasMrk)->C7_I_APLIC,;																			//[17]Aplicação
						(_cAliasMrk)->C7_I_CDINV + " - " + (_cAliasMrk)->ZZI_DESINV,;									//[18]Investimento
						(_cAliasMrk)->C7_I_CMPDI})																			//[19]Compra Direta										  							

		(_cAliasMrk)->(DBSkip())
	EndDo

	U_ITListBox( 'Geração Planilha' , aCampPla , aLogPla , .T. , 1 )
EndIf

FwRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: ACOM016E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/12/2015
Descrição---------: Executa eliminação por resíduo de SCs e Pedidos de Compras selecionados.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM016E()

Local _nI 			:= 1 As Numeric
Local _aAlias 		:= {} As Array
Local _aEmail 		:= {} As Array
Local _cSolCpr		:= "" As Character
Local _cAprSolCpr	:= "" As Character

_lOK  :=.F.
cMens1:= ""
_nTam :=245
_nCol :=009 
_nColB:=50
_nColC:=_nColB+80
_nLin :=005 
DEFINE MSDIALOG oDlg TITLE "ELIMINAR POR RESÍDUO" From 0,0 to 300,500 Of oMainWnd PIXEL
	
		oTPanel1:= TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,450,200,.T.,.F.)
		
		@ _nLin,_nCol Say "ELIMINA POR RESÍDUO OS REGISTROS SELECIONADOS ?"	Of oTPanel1 Pixel 
		_nLin+=11
		
		oTFolder1 := TFolder():New( _nLin,005,{"Justifique se desejar:"},,oTPanel1,,,,.T.,,_nTam,090 )
	
		@ 005,005 Get oMemo01 var cMens1 MEMO Size 230,60  of oTFolder1:aDialogs[1] Pixel
		_nLin+=95		
		TButton():New(_nLin,_nColB, ' Confirma ', oTPanel1,{|| _lOK:=.T. , oDlg:END() },70,15,,,,.T.)
		TButton():New(_nLin,_nColC, ' Cancela ' , oTPanel1,{|| _lOK:=.F. , oDlg:END() },70,15,,,,.T.)
		
	ACTIVATE MSDIALOG oDlg Centered

If !_lOK//(U_ITMsg("Elimina por resíduo os registros selecionados?","Eliminar por resíduo",,2,2))
	oMrkBrowse:Gotop()
	Return .T.
EndIf
	

If MV_PAR08 == 2 //Solicitação de Compra

	_aEmail := {}

	For _nI := 1 to Len(_aRegsSC1)
		SC1->(DBSetOrder(1))
		If SC1->(DBSeek(_aRegsSC1[_nI][1]+_aRegsSC1[_nI][2]+_aRegsSC1[_nI][3]))
			
			BEGIN TRANSACTION
					
				SC1->(RecLock("SC1",.F.))
				SC1->C1_I_USREL := __cUserId
				SC1->C1_I_DTELR := Date()
				SC1->C1_I_HRELR	:= Time()
				If SC1->(FIELDPOS("C1_I_JUERE")) <> 0
					SC1->C1_I_JUERE	:= cMens1 
				EndIf	
				SC1->(MSUnLock())
				LTNEWPROC:=.F.
				//MA235SC(nPerc, dEmisDe  , dEmisAte         , cCodigoDe  , cCodigoAte , cProdDe  , cProdAte        , cFornDe, cFornAte, dDatPrfde, dDatPrfAte        , lSemOp, cItemDe     , cItemAte   ,aRecSC1)
				MA235SC(100, CTOD("") ,CTOD("31/12/2030"), SC1->C1_NUM, SC1->C1_NUM,Space(15) ,"ZZZZZZZZZZZZZZZ",Space(6),"ZZZZZZ" ,CTOD("")  ,CTOD("31/12/2030") ,.T.    , SC1->C1_ITEM, SC1->C1_ITEM)
							
				aAdd(_aEmail,{SC1->C1_FILIAL+" - "+AllTrim( Posicione('SM0',1,"01"+SC1->C1_FILIAL,'M0_FILIAL') ),;
						SC1->C1_NUM,;
						cMens1,;
						DToC(SC1->C1_I_DTELR),;
						SC1->C1_I_USREL + " - " +UsrFullName(SC1->C1_I_USREL),; //Autor da Eliminação
						SC1->C1_USER  + " - " +UsrFullName(SC1->C1_USER),; //Solicitante
						AllTrim(SC1->C1_I_CODAP) + IIf(!Empty(AllTrim(SC1->C1_I_CODAP))," - " +UsrFullName(SC1->C1_I_CODAP),""),; //Aprovador
						SC1->C1_ITEM,;
						SC1->C1_FORNECE + " - " + SC1->C1_LOJA + " " + Posicione("SA2",1,xFilial("SA2")+SC1->C1_FORNECE+SC1->C1_LOJA,"A2_NREDUZ"),;							
						SC1->C1_PRODUTO,;
						SC1->C1_DESCRI,;
						SC1->C1_UM,;
						AllTrim(Transform(SC1->C1_QUANT,PesqPict("SC1","C1_QUANT"))) ,;
						AllTrim(Transform(SC1->C1_PRECO,PesqPict("SC1","C1_PRECO"))) ,;
						AllTrim(Transform(SC1->C1_QUJE,PesqPict("SC1","C1_QUJE"))) ,;
						DToC(SC1->C1_DATPRF),;
						AllTrim(Transform(SC1->C1_QUANT - SC1->C1_QUJE,PesqPict("SC1","C1_QUANT")))})		

				END TRANSACTION
			EndIf
	Next _nI
		
ElseIf MV_PAR08 == 1 //Pedido de Compra

	_acontrol := {}
	_aEmail := {}
	ZY1->(DBSetOrder(1))
	SC7->(DBSetOrder(1))
	
	Begin Sequence
	BEGIN TRANSACTION
	
	For _nI := 1 to Len(_aRegsSC7)
		//Marca pedido de compra como eliminado por residuo
		If SC7->(DBSeek(_aRegsSC7[_nI][1]+_aRegsSC7[_nI][2]+_aRegsSC7[_nI][3]))
			SC7->(RecLock("SC7",.F.))
			SC7->C7_I_USREL := __cUserId
			SC7->C7_I_DTELR := Date()
			SC7->C7_I_HRELR	:= Time()
			SC7->C7_RESIDUO :=  "S"
			SC7->C7_ENCER 	:=  "E"
			SC7->C7_QTDACLA := 0  //Garante que quantidade a classificar não fica negativa
			If SC7->(FIELDPOS("C7_I_JUERE")) <> 0
				SC7->C7_I_JUERE	:= cMens1
			EndIf 
			SC7->(MSUnLock())
			
			//Atualiza B2_SALPEDI
			SB2->(DBSetOrder(1))
			If SB2->(DBSeek(SC7->C7_FILIAL+SC7->C7_PRODUTO+SC7->C7_LOCAL))
				If SB2->B2_SALPEDI - (SC7->C7_QUANT - SC7->C7_QUJE) >= 0
					SB2->(RecLock("SB2",.F.))
					SB2->B2_SALPEDI :=  SB2->B2_SALPEDI - (SC7->C7_QUANT - SC7->C7_QUJE)
					SB2->(MSUnLock())
				Else
					SB2->(RecLock("SB2",.F.))
					SB2->B2_SALPEDI :=  0
					SB2->(MSUnLock())
				EndIf
				
				//Busca Sol Cpr 
				SC1->(DBSetOrder(1))
				If SC1->(DBSeek(SC7->C7_FILIAL+SC7->C7_NUMSC + SC7->C7_ITEMSC))
					_cSolCpr    := AllTrim(SC1->C1_USER)
					_cAprSolCpr := AllTrim(SC1->C1_I_CODAP)
				EndIf

				aAdd(_aEmail,{SC7->C7_FILIAL +" - "+AllTrim( Posicione('SM0',1,"01"+SC7->C7_FILIAL,'M0_FILIAL') ),;
						SC7->C7_NUM,;
						SC7->C7_FORNECE + " - " + SC7->C7_LOJA + " " + Posicione("SA2",1,xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,"A2_NREDUZ"),;
						U_ITRetBox( SC7->C7_I_APLIC , "C7_I_APLIC" ) ,; //Aplicação
						cMens1,;
						DToC(SC7->C7_I_DTELR),;
						SC7->C7_I_USREL + " - " + UsrFullName(SC7->C7_I_USREL),; //Autor da Eliminação
						SC7->C7_USER + IIf(!Empty(AllTrim(SC7->C7_USER))," - " +UsrFullName(SC7->C7_USER),"") ,; //Comprador
						IIf(Empty(_cSolCpr),"",_cSolCpr + " - " + UsrFullName(_cSolCpr)),; // Solictante
						IIf(Empty(_cAprSolCpr),"",_cAprSolCpr + " - " + UsrFullName(_cAprSolCpr)),; //Aprovador
						SC7->C7_ITEM,;
						SC7->C7_PRODUTO,;
						SC7->C7_DESCRI,;
						SC7->C7_UM,;
						AllTrim(Transform(SC7->C7_QUANT,PesqPict("SC7","C7_QUANT"))) ,;
						AllTrim(Transform(SC7->C7_PRECO,PesqPict("SC7","C7_PRECO"))) ,;
						AllTrim(Transform(SC7->C7_QUJE,PesqPict("SC7","C7_QUJE"))) ,;
						DToC(SC7->C7_DATPRF),;
						AllTrim(Transform(SC7->C7_QUANT - SC7->C7_QUJE,PesqPict("SC7","C7_QUANT")))})		
			Else
				FWAlertError("Falha de atualização de saldo de produtos!. Processamento não será efetuado","ACOM01602")
				Disarmtransaction()
				Break
			EndIf
		EndIf
		
		//Alimenta ou atualiza controle de pedidos parciais
		_npos := aScan(_acontrol,{|_vAux|_vAux[2] == _aRegsSC7[_nI][2]})
		If   _npos == 0
			aAdd(_acontrol,{_aRegsSC7[_nI][1],_aRegsSC7[_nI][2],IIf(SC7->C7_QUJE> 0,1,0)})
		Else
			If SC7->C7_QUJE > 0
				_acontrol[_npos][3] := 1
			EndIf
		EndIf
	Next _nI

	If  Len(_aRegsSC7) > 0
		If SC7->(DBSeek(_aRegsSC7[1,1]+_aRegsSC7[1,2] )) .And. ZY1->(DBSeek(SC7->C7_FILIAL+SC7->C7_NUM))
            _lEncerraMonitoramento:=.T.
			While SC7->C7_FILIAL ==  _aRegsSC7[1,1] .And. SC7->C7_NUM == _aRegsSC7[1,2] .And. SC7->(!Eof())
				If SC7->C7_ENCER != "E"
				   _lEncerraMonitoramento:=.F.
				EndIf
				SC7->( DBSkip() )
			EndDo

			If _lEncerraMonitoramento .And. SC7->(DBSeek(_aRegsSC7[1,1]+_aRegsSC7[1,2] ))
				If ZY1->(DBSeek(SC7->C7_FILIAL+SC7->C7_NUM))
					While ZY1->ZY1_FILIAL == SC7->C7_FILIAL .And. ZY1->ZY1_NUMPC == SC7->C7_NUM .And. ZY1->(!Eof())
						ZY1->(RecLock("ZY1", .F.))
						ZY1->ZY1_ENCMON	:= "S"
						ZY1->(MSUnLock())						
						ZY1->( DBSkip() )
					EndDo
				EndIf
			EndIf
		EndIf
	EndIf
	
	//Repassa pedidos de compra e apaga SCR de pedidos de compras 
	//eliminados por resíduos que não tiveram entrega parcial
	For _nI := 1 to Len(_acontrol)
	
		DBSelectArea("SCR")
		SCR->(DBSetOrder(1))
		SCR->(DBGoTop())
		If _acontrol[_nI][3] == 0 .And. SCR->(DBSeek(_acontrol[_nI][1]+"PC"+_acontrol[_nI][2]))
		
			//Verifica se tem aprovado
			_ltemaprov := .F.
			SC7->(DBSetOrder(1))
			If SC7->(DBSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)))
				While SC7->C7_FILIAL == SCR->CR_FILIAL .And. SC7->C7_NUM == AllTrim(SCR->CR_NUM)
					If SC7->C7_CONAPRO == "L"
						_ltemaprov := .T.
					Else
						If SC7->C7_RESIDUO ==  "S" //Se foi eliminado por residuo marca como liberado para seguir a rotina padrão
							SC7->(RecLock("SC7",.F.))
							SC7->C7_CONAPRO	:= "L" 
							SC7->(MSUnLock())
						EndIf		  
					EndIf
					SC7->(DBSkip())
				EndDo
			EndIf
			
			//apaga todas as alçadas se pedido não teve nenhum item aprovado antes de eliminar residuos
			While AllTrim(SCR->CR_FILIAL) == AllTrim(_acontrol[_nI][1]) .And. AllTrim(SCR->CR_NUM) == AllTrim(_acontrol[_nI][2]) .And. AllTrim(SCR->CR_TIPO) == "PC" .And. !_ltemaprov
				SCR->(RecLock("SCR",.F.))
				SCR->(DbDelete())
				SCR->(MSUnLock())
				SCR->(DBSkip())
			EndDo
		EndIf
	Next _nI
	
	END TRANSACTION	
	End Sequence
	
EndIf

//--------------------------------------------------------
//Envio do Email aos Responsáveis
//--------------------------------------------------------
If Len(_aEmail) > 0
	ACOM016M(_aEmail,If(MV_PAR08 == 1,1,2))
EndIf


//--------------------------------------------------------
//Retorna as colunas para o preenchimento da FWMarkBrowse
//--------------------------------------------------------
FWMsgRun( ,{|| _aAlias := ACOM016QRY() } , 'Aguarde!' , 'Verificando os registros...' )
	
_cAliasMrk	:= _aAlias[1]
_aColumns 	:= _aAlias[2]

//----------------------
//Criação da MarkBrowse
//----------------------
oMrkBrowse:SetAlias(_cAliasMrk)
oMrkBrowse:Refresh()
oMrkBrowse:Gotop()

FWAlertSuccess("Processamento concluido","ACOM01603")

Return .T.

/*
===============================================================================================================================
Programa----------: ACOM016M
Autor-------------: Igor Melgaço
Data da Criacao---: 07/06/2023
Descrição---------: Prepara os dados para o envio de Emails.
Parametros--------: _nTipo = 1 Pedido de Compra ; 2 Solicitacao de Compra
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM016M(_aDados As Array,_nTipo As Numeric)

Local _aMensag    := {} As Array
Local _nColUser   := 0 As Numeric
Local _nColItem   := 0 As Numeric
Local _nColFilial := 0 As Numeric
Local _nColDoc    := 0 As Numeric
Local _nM         := 0 As Numeric

_nColUser   := IIf(_nTipo=1,8,6)
_nColItem   := IIf(_nTipo=1,11,8)
_nColFilial := 1
_nColDoc    := 2

aSort(_aDados,,,{|x,y| x[_nColUser]+x[_nColFilial]+x[_nColDoc]+x[_nColItem] < y[_nColUser]+y[_nColFilial]+y[_nColDoc]+y[_nColItem]})

_cRespAnt := _aDados[1,_nColUser] + _aDados[1,1] + _aDados[1,2]

For _nM := 1 to Len(_aDados)
	If (_aDados[_nM,_nColUser] + _aDados[_nM,1] + _aDados[_nM,2]) <> _cRespAnt
		ACOM016J(_nTipo,_aMensag)
		_aMensag := {}
	EndIf
	
	aAdd(_aMensag,_aDados[_nM])
	_cRespAnt := _aDados[_nM,_nColUser] + _aDados[_nM,1] + _aDados[_nM,2]
Next

ACOM016J(_nTipo,_aMensag)

Return .T.

/*
===============================================================================================================================
Programa----------: ACOM016J
Autor-------------: Igor Melgaço
Data da Criacao---: 07/06/2023
Descrição---------: Executa o envio de Emails.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM016J(_nTipo As Numeric,_aMensag As Array)

Local cTit      := "Eliminação de Residuo" As Character
Local cGetAssun := "Eliminação de Resíduo " As Character
Local _aConfig	:= U_ITCFGEML('') As Array
Local _cEmlLog	:= "" As Character
Local _cMsgEml	:= "" As Character
Local cGetCc	:= "" As Character
Local cGetPara	:= "" As Character
Local _cEmail_2 := "" As Character
Local _cEmail_3 := "" As Character
Local _cEmail_4 := "" As Character
Local _nJ 		:= 0 As Numeric
Local _nK 		:= 0 As Numeric
Local _nI 		:= 0 As Numeric
Local _nL 		:= 0 As Numeric
Local _nTam 	:= Len(SC7->C7_USER) As Numeric
Local _nItem 	:= 0 As Numeric
Local _aCabec 	:= {} As Array

_nItem := IIf(_nTipo = 1, 11,8 )
_nColAut := IIf(_nTipo = 1, 7,5)

If Len(_aCabec) = 0
	//Monta os titulos das colunas
	aAdd(_aCabec,{"Filial","04","left"})
	aAdd(_aCabec,{IIf(_nTipo=1,"Pedido","Solic. Compra"),"04","left"})

	If _nTipo = 1
		aAdd(_aCabec,{"Fornecedor","04","left"})
		aAdd(_aCabec,{IIf(_nTipo=1,"Aplicação","Legenda do tipo de compra"),"04","left"})		//04
	EndIf

	aAdd(_aCabec,{"Justificativa","11","left"})
	aAdd(_aCabec,{"Data da Elimanação","11","left"})
	aAdd(_aCabec,{"Autor da Eliminação","11","left"})
	aAdd(_aCabec,{If(_nTipo = 1,"Comprador","Solicitante"),"22","left"} )
	
	If _nTipo = 1
		aAdd(_aCabec,{"Solicitante","11","left"})
	EndIf
	aAdd(_aCabec,{"Aprovador","11","left"})
	aAdd(_aCabec,{"Item","04","left"})

	If _nTipo = 2
		aAdd(_aCabec,{"Fornecedor","04","left"})
	EndIf

	aAdd(_aCabec,{"Produto","10","left"})
	aAdd(_aCabec,{"Descrição",If(_nTipo = 1,"38","28"),"left"})
	aAdd(_aCabec,{"Unid","08","center"})
	aAdd(_aCabec,{"Qtd","08","center"})
	aAdd(_aCabec,{"Preço","08","center"})
	aAdd(_aCabec,{"Qtd Entregue","08","center"})
	aAdd(_aCabec,{IIf(_nTipo=1,"Dt Entrega","Data prev. da Necessidade"),"08","left"})//13 
	aAdd(_aCabec,{"Qtd de Residuo","08","center"})
EndIf 

cGetPara  := LOWER(AllTrim(UsrRetMail(Subs(_aMensag[1,_nColAut+1],1,_nTam))))
_cEmail_2  := LOWER(AllTrim(UsrRetMail(Subs(_aMensag[1,_nColAut+2],1,_nTam))))

If _nTipo = 1
	_cEmail_3  := LOWER(AllTrim(UsrRetMail(Subs(_aMensag[1,_nColAut+3],1,_nTam))))
	_cEmail_4  := LOWER(AllTrim(UsrRetMail(Subs(_aMensag[1,_nColAut],1,_nTam))))
Else
	_cEmail_3  := LOWER(AllTrim(UsrRetMail(Subs(_aMensag[1,_nColAut],1,_nTam))))
EndIf

cGetCc    := ""
cGetAssun += IIf(_nTipo=1,"do Pedido de Compra Nr ","da Solicitação de Compra Nr ") +_aMensag[1][2]

_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+cTit+'</title></head>'
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
_cMsgEml += '	     <td class="titulos"><center>'+cTit+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados da Eminação de Residuo</b></td>'
_cMsgEml += '    </tr>'

For _nL := 1 to _nItem-1
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="'+_aCabec[_nL,3]+'" width="30%"><b>'+_aCabec[_nL,1]+' </b></td>'
	_cMsgEml += '      <td class="itens" >'+ _aMensag[1][_nL] +'</td>' 
	_cMsgEml += '    </tr>'
Next

_cMsgEml += '    <tr>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'

_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="1300">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="'+AllTrim(Str(Len(_aCabec)+1-_nItem))+'" class="grupos"><b>Itens do Pedido</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'

For _nK := _nItem To Len(_aCabec)
	_cMsgEml += '      <td class="itens" align="'+_aCabec[_nK,3]+'"   width="'+_aCabec[_nK,2]+'%"><b>'+_aCabec[_nK,1]+'</b></td>'
Next

_cMsgEml += '    </tr>'

For _nI := 1 To Len(_aMensag)
	_cMsgEml += '    <tr>'
	For _nJ := _nItem  To Len(_aCabec)
		_cMsgEml += '      <td class="itens" align="'+_aCabec[_nJ,3]+'" width="'+_aCabec[_nJ,2]+'%">'+ _aMensag[_nI][_nJ]+'</td>'
	Next
_cMsgEml += '    </tr>'

Next _nI

_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [ACOM016]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

U_ITENVMAIL( _aConfig[01], cGetPara, cGetCc, "", cGetAssun, _cMsgEml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

If !Empty(_cEmail_2)
	U_ITENVMAIL( _aConfig[01], _cEmail_2, cGetCc, "", cGetAssun, _cMsgEml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
EndIf

If !Empty(_cEmail_3)
	U_ITENVMAIL( _aConfig[01], _cEmail_3, cGetCc, "", cGetAssun, _cMsgEml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
EndIf

If !Empty(_cEmail_4)
	U_ITENVMAIL( _aConfig[01], _cEmail_4, cGetCc, "", cGetAssun, _cMsgEml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
EndIf

Return 
