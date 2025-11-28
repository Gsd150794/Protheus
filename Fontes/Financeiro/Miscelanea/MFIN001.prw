/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |08/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Lucas Borges  |03/05/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'FWMVCDef.ch'

/*
===============================================================================================================================
Programa----------: MFIN001                                   
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 29/07/2015                                                                                                
Descrição---------: Rotina responsável por limpar o flag para reimpressão de cheques
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN001()

Local aColumns		:= {}
Local bChkMarca		:= {|| IIf( aScan( aRegsSEF , { |x| x[1] == (_cAlias)->SEFRECNO } ) == 0 , 'LBNO' , 'LBOK' ) }
Local bSelMarca		:= {|| ( IIf( ( nPos := aScan( aRegsSEF , { |x| x[1] == (_cAlias)->SEFRECNO } ) ) == 0 , ( aAdd( aRegsSEF , { (_cAlias)->SEFRECNO } ) , lMarcou := .T. ) , ( aDel( aRegsSEF , nPos ) , aSize( aRegsSEF , Len( aRegsSEF ) -1 ) ) ) ) }
Local bAllMarca		:= {|| IIf( Empty( aRegsSEF ) , aRegsSEF := aClone( aRegsAll ) , aRegsSEF := {} ) , oMrkBrowse:Refresh() , oMrkBrowse:GoTop() }
Local nX			:= 0
Local _aStru		:= {}
Local _cQuery		:= ""
Local _cAlias		:= GetNextAlias()

Private aRegsSEF	:= {}
Private aRegsAll	:= {}
Private cPerg		:= "MFIN001"
Private aRotina	 	:= Menudef()

If !Pergunte(cPerg,.T.)
     Return
EndIf

// Montra estrutura para ser usada na tabela temporária
aAdd(_aStru,{"SEF_OK"		,"C",01,00})
aAdd(_aStru,{"EF_VALOR"		,"N",GetSX3Cache("EF_VALOR","X3_TAMANHO"),GetSX3Cache("EF_VALOR","X3_DECIMAL")})
aAdd(_aStru,{"EF_DATA"		,"D",GetSX3Cache("EF_DATA","X3_TAMANHO"),00})
aAdd(_aStru,{"EF_PREFIXO"	,"C",GetSX3Cache("EF_PREFIXO","X3_TAMANHO"),00})
aAdd(_aStru,{"EF_TITULO"	,"C",GetSX3Cache("EF_TITULO","X3_TAMANHO"),00})
aAdd(_aStru,{"EF_FORNECE"	,"C",GetSX3Cache("EF_FORNECE","X3_TAMANHO"),00})
aAdd(_aStru,{"EF_LOJA"		,"C",GetSX3Cache("EF_LOJA","X3_TAMANHO"),00})
aAdd(_aStru,{"EF_NUM"		,"C",GetSX3Cache("EF_NUM","X3_TAMANHO"),00})
aAdd(_aStru,{"SEFRECNO"		,"N",08,00})

_cQuery += " SELECT ' ' SEF_OK, EF_VALOR, EF_DATA, EF_PREFIXO, EF_TITULO, EF_FORNECE, EF_LOJA, EF_NUM, SEF.R_E_C_N_O_ SEFRECNO"
_cQuery += " FROM " + RetSqlName("SEF") + " SEF"
_cQuery += " WHERE SEF.D_E_L_E_T_ = ' '"
_cQuery += " AND SEF.EF_FILIAL = '" + xFilial("SEF") + "' "
_cQuery += " AND SEF.EF_NUM >= '" + MV_PAR01 + "' "
_cQuery += " AND SEF.EF_NUM <= '" + MV_PAR02 + "' "
_cQuery += " AND SEF.EF_BANCO = '" + MV_PAR03 + "' "
_cQuery += " AND SEF.EF_AGENCIA = '" + MV_PAR04 + "' "
_cQuery += " AND SEF.EF_CONTA = '" + MV_PAR05 + "' "
_cQuery += " AND SEF.EF_IMPRESS = 'S' "
_cQuery += " ORDER BY EF_DATA,EF_NUM,EF_FORNECE,EF_LOJA"

// Cria arquivo de dados temporário
_oTempTable := FWTemporaryTable():New( _cAlias, _aStru )
_oTempTable:Create()
SQLToTrb(_cQuery, _aStru, _cAlias)

IncProc('Lendo os dados...')

(_cAlias)->( DBGoTop() )
While (_cAlias)->(!Eof())
	aAdd( aRegsAll , { (_cAlias)->SEFRECNO } )
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBGoTop() )

If !(_cAlias)->(Eof())
	For nX := 2 To Len(_aStru)-1 // retiro 1ª e última colunas
		aAdd(aColumns,FWBrwColumn():New())
		aColumns[Len(aColumns)]:SetData( &("{||"+_aStru[nX][1]+"}") )
		aColumns[Len(aColumns)]:SetTitle(GetSX3Cache(_aStru[nX][1],"X3_TITULO")) 
		aColumns[Len(aColumns)]:SetSize(_aStru[nX][3]) 
		aColumns[Len(aColumns)]:SetDecimal(_aStru[nX][4])
		aColumns[Len(aColumns)]:SetPicture(GetSX3Cache(_aStru[nX][1],"X3_PICTURE"))
	Next nX

	//=========================
	// Criação da MarkBrowse
	//=========================
	oMrkBrowse:= FWMarkBrowse():New()
	oMrkBrowse:SetDataTable(.T.)
	oMrkBrowse:SetAlias(_cAlias)
	oMrkBrowse:AddMarkColumns( bChkMarca , bSelMarca , bAllMarca )
	oMrkBrowse:SetDescription("")
	oMrkBrowse:SetColumns(aColumns)
	oMrkBrowse:Activate()

Else
	MsgStop("Não foram encontrados registros para os parâmetros informados.",'MFIM001')
EndIf

//Exclui a tabela
(_cAlias)->(DBCloseArea())
_oTempTable:Delete()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 29/07/2015
Descrição---------: Função utilizada para criação do menu
Parametros--------: Nenhum
Retorno-----------: aRotina - Opções de menu
===============================================================================================================================
*/
Static Function MenuDef()     
Local aRot := {}

ADD OPTION aRot Title 'Limpa Flag'		Action 'Processa( {|| U_F001REIMP() } )'		OPERATION 2 ACCESS 0

Return(Aclone(aRot))

/*
===============================================================================================================================
Programa----------: F001REIMP
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 29/07/2015
Descrição---------: Função utilizada para limpar a flag de reimpressão
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F001REIMP()

Local aArea			:= FWGetArea()
Local nX			:= 0
Local nLenRegs 		:= 0
Local cInfo			:= ""

//===================================
// Destravo os registros marcados
//===================================
nLenRegs := Len(aRegsSEF)

If nLenRegs > 0
	
	ProcRegua(nLenRegs)
	
	BEGIN TRANSACTION
	
		For nX := 1 To Len(aRegsSEF)
			
			IncProc('Processando ['+ StrZero( nX , 6 ) +'] de ['+ StrZero( nLenRegs , 6 ) +']')
			
			DBSelectArea('SEF')
			SEF->( DBGoTo( aRegsSEF[nX][1] ) )
			RecLock( "SEF" , .F. )
				SEF->EF_IMPRESS := " "
			SEF->( MSUnLock() )
			
		Next nX
		
	END TRANSACTION
	
	If nLenRegs == 1
		cInfo := 'Foi processado 1 cheque.'
	Else
		cInfo := "Foram processados " + AllTrim(Str(nLenregs)) + " cheques."
	EndIf

	MsgInfo(cInfo)
	oMrkBrowse:GetOwner():End()

Else

	MsgAlert("Não foi selecionado nenhum item para o processamento!","MFIN002")

EndIf

FreeUsedCode()  //libera codigos de correlativos reservados pela MayIUseCode()

FWRestArea(aArea)

Return
