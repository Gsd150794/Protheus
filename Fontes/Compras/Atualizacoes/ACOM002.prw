/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 17/03/2025 | Chamado 50218. Inclído filtro correto dos CFOPs contemplados na operação
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"

/*
===============================================================================================================================
Programa--------: ACOM002
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 31/07/2024
Descrição-------: Cadastro de descontos Tetra Pak
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ACOM002

Local _oBrowse	:= Nil

// Configura e inicializa a Classe do Browse
_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias('ZM5')
_oBrowse:SetDescription('Cadastro de Descontos Tetra Pak')
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa--------: MenuDef
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 31/07/2024
Descrição-------: Rotina para criação do menu na tela inicial
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.ACOM002' OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.ACOM002' OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.ACOM002' OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.ACOM002' OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.ACOM002' OPERATION 8 ACCESS 0
ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.ACOM002' OPERATION 9 ACCESS 0
ADD OPTION aRotina TITLE 'Rec. Custo' ACTION 'U_ACOM002R()'	   OPERATION 10 ACCESS 0

Return( aRotina )

/*
===============================================================================================================================
Programa--------: ModelDef
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 31/07/2024
Descrição-------: Rotina para criação do modelo de dados para o processamento
Parametros------: Nenhum
Retorno---------: _oModel -> O -> Modelo de dados
===============================================================================================================================
*/
Static Function ModelDef()

Local _oStruZM5	:= FWFormStruct(1,'ZM5',{|_cCampo|ACOM002Cpo(_cCampo,1)})
Local _oStruGrid:= FWFormStruct(1,'ZM5',{|_cCampo|ACOM002Cpo(_cCampo,2)})
Local _oModel	:= MPFormModel():New( "ACOM002M" ,/*bPreValidacao*/,{|| a002VldGrv(_oModel)},/*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
Local _aAuxFWDGat:={}

// Monta a estrutura dos gatilhos
_aAuxFWDGat := FwStruTrigger('ZM5_PRODUT','ZM5_DESC','Posicione("SB1",1,xFilial("SB1")+M->ZM5_PRODUTO,"B1_DESC")',.F.)
_oStruGrid:AddTrigger(_aAuxFWDGat[01],_aAuxFWDGat[02],_aAuxFWDGat[03],_aAuxFWDGat[04])

// Monta a estrutura dos campos
_oModel:AddFields('MdFieldZM5',, _oStruZM5)
_oModel:AddGrid('MdGridZM5','MdFieldZM5',_oStruGrid,,{|_oModel|a002LinOk(_oModel)})
_oModel:SetRelation('MdGridZM5',{{'ZM5_FILIAL','xFilial("ZM5")'},;
                                {'ZM5_DTINI','ZM5_DTINI'},{'ZM5_DTFIM','ZM5_DTFIM'}},;
								ZM5->( IndexKey(1)))

_oModel:SetDescription('Cadastro de Descontos Tetra Pak')
_oModel:GetModel('MdGridZM5'):SetUniqueLine({'ZM5_PRODUT'})
_oModel:SetPrimaryKey({'ZM5_FILIAL','ZM5_PRODUT','ZM5_DTINI','ZM5_DTFIM'})

Return(_oModel)

/*
===============================================================================================================================
Programa--------: ViewDef
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 31/07/2024
Descrição-------: Rotina para criação da view de dados para exibição na tela
Parametros------: Nenhum
Retorno---------: _oView - O -> Objeto da View
===============================================================================================================================
*/
Static Function ViewDef()

Local _oModel	:= FWLoadModel('ACOM002')
Local _oStruZM5	:= FWFormStruct(2,'ZM5',{|_cCampo|ACOM002Cpo(_cCampo,1)})
Local _oStruGRID:= FWFormStruct(2,'ZM5',{|_cCampo|ACOM002Cpo(_cCampo,2)})
Local _oView	:= FWFormView():New()

_oView:SetModel(_oModel)
_oView:AddField('VIEW_ZM5',_oStruZM5,'MdFieldZM5')
_oView:AddGrid(	'GRID_ZM5',_oStruGRID,'MdGridZM5')

_oView:CreateHorizontalBox('MAIN',15)
_oView:CreateHorizontalBox('GRID',85)

_oView:SetOwnerView('VIEW_ZM5','MAIN')
_oView:SetOwnerView('GRID_ZM5','GRID')

Return(_oView)

/*
===============================================================================================================================
Programa--------: ACOM002Cpo
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 31/07/2024
Descrição-------: Rotina para definição da exibição dos campos na tela
Parametros------: _cCampo -> C -> campo a ser validado
				  _nOpc -> N -> 1-Model - 2-View
Retorno---------: _lRet -> L -> .T. Inclui campo - .F. Não incluiu campo
===============================================================================================================================
*/
Static Function ACOM002Cpo(_cCampo,_nOpc)
Local _lRet := (Upper(AllTrim(_cCampo)) $ 'ZM5_FILIAL;ZM5_DTINI;ZM5_DTFIM')

If _nOpc == 2
	_lRet := !_lRet
EndIf

Return( _lRet )
/*
===============================================================================================================================
Programa--------: a002LinOk
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 31/07/2024
Descrição-------: Validacao de linha do grid
Parametros------: _oModel -> O -> Modelo de Dados
Retorno---------: _lRet -> L -> .T. - Linha OK - .F. - Linha com problema
===============================================================================================================================
*/
Static Function a002LinOk(_oModel)

Local _lRet		:= .T.
If ( _oModel:isInserted() .Or. _oModel:IsModified() ) .And. !_oModel:IsDeleted()
	_lRet := A002UnqKey(_oModel)
	If !_lRet
		Help(" ",1,"ACOM00201",,"Registro já cadastrado.",1,4, NIL, NIL, NIL, NIL, NIL, {"Altere o produto ou a vigência da regra"})
	EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: a002VldGrv
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 31/07/2024
Descrição-------: Validacao de linhas ativas no grid
Parametros------: _oModel -> O -> Modelo de Dados
Retorno---------: _lRet -> L -> .T. - Modelo OK - .F. - Modelo com problema
===============================================================================================================================
*/
Static Function a002VldGrv(_oModel)

Local _lRet	 	 := .T.
Local _nCount 	 := 0
Local _nI		 :=0
Local _oModelGRID := _oModel:GetModel('MdGridZM5')

If Empty(FwFldGet("ZM5_DTINI")) .Or. Empty(FwFldGet("ZM5_DTFIM"))
	Help(" ",1,"ACOM00202",,"Período informado inválido",1,1)
	_lRet := .F.
ElseIf FwFldGet("ZM5_DTINI") > FwFldGet("ZM5_DTFIM")
	Help(" ",1,"ACOM00203",,"Data Inicial maior que data final do período.",1,1)
	_lRet := .F.
EndIf

If _lRet  
	For _nI := 1 To _oModelGRID:Length() 
		_oModelGRID:GoLine(_nI) 
		If _oModelGRID:IsDeleted()
			_nCount := (_nCount+1)
		Else
			_lRet := A002UnqKey(_oModelGRID)
			If !_lRet
		    	Help(" ",1,"ACOM00204",,"Período Já cadastrado.",1,4, NIL, NIL, NIL, NIL, NIL, {"Altere o Período informado."})
				Exit
			EndIf
		EndIf
	Next _nI

	If _lRet .And. _oModelGRID:length()==_nCount
		_lRet :=.F.
		Help(" ",1,"ACOM00205",,"Registro sem linhas no grid",1,4, NIL, NIL, NIL, NIL, NIL, {"Informe pelo menos um item no grid."})	
	EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: A002UnqKey
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 31/07/2024
Descrição-------: Validacao da chave única
Parametros------: _oModel -> O -> Modelo de Dados
Retorno---------: _lRet -> L -> .T. - Linha OK - .F. - Linha com problema
===============================================================================================================================
*/
Static Function A002UnqKey(_oModel)

Local _lRet		:= .T.
Local _cAlias   := GetNextAlias()
Local _cProd    := _oModel:GetValue('ZM5_PRODUT')
Local _cDtIni   := DToS(FwFldGet('ZM5_DTINI'))
Local _cDtFim   := DToS(FwFldGet('ZM5_DTFIM'))
Local _nRecno	:= _oModel:GetDataId()

BeginSql alias _cAlias
    SELECT COUNT(1) QTD FROM %Table:ZM5% 
	WHERE D_E_L_E_T_ = ' '
	AND ZM5_FILIAL = %xFilial:ZM5% 
    AND ZM5_PRODUT = %exp:_cProd%
    AND ZM5_DTINI = %exp:_cDtIni%
    AND ZM5_DTFim = %exp:_cDtFim%
	AND R_E_C_N_O_ <> %exp:_nRecno%
EndSql
If (_cAlias)->QTD > 0
    _lRet := .F.
EndIf
(_cAlias)->(DBCloseArea())

Return( _lRet )

/*
===============================================================================================================================
Programa--------: ACOM002R
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 31/07/2024
Descrição-------: Recalcula o custo dos movimentos internos
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ACOM002R

Local _aArea := FWGetArea()
Local _oSelf := Nil

tNewProcess():New(	"ACOM002"										,; // Função inicial
					"Atualiza Custo Descontos Tetra Pak"			,; // Descrição da Rotina
					{|_oSelf| AtCustoP(_oSelf) }					,; // Função do processamento
					"Atualiza custo dos movimentos internos referente aos descontos Tetra Pak ",;// Descrição da Funcionalidade
					"ACOM002"										,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
					.T.                                              ) // Se .T. cria apenas uma regua de processamento.

FWRestArea(_aArea)

Return

Static Function AtCustoP(_oSelf)

Local _dUlMes	:= MVUlmes()
Local _cAlias	:= GetNextAlias()
Local _nQtdReg	:= 0
Local _nDecimal := GetSX3Cache("D1_CUSTO","X3_DECIMAL")
Local _cDecimal := "% " + CValToChar(_nDecimal)+ " %"
Local _cCFOPS	:= "% AND D2_CF IN "+ FormatIn( AllTrim(SuperGetMV("IT_CFTETRS",.F.,"6201/5201")),'/') + "%"
Local _cCFOPE	:= "% AND D1_CF IN "+ FormatIn( AllTrim(SuperGetMV("IT_CFTETRE",.F.,"1101/2101/1122/2122")),'/') + "%"
If MV_PAR01 <= _dUlMes
	FWAlertError("A data inicial de processamento é menor ou igual ao fechamento do estoque (MV_ULMES): "+DToC(_dUlMes),"ACOM00201")
	Return .F.
EndIf

DBSelectArea("SD3")

_oSelf:SetRegua1(2)
_oSelf:IncRegua1("Buscando dados para serem processados...")

BeginSql Alias _cAlias
	SELECT SD3.R_E_C_N_O_ RECNO, D1_CUSTO*(ZM5_AVD+ZM5_QSR+ZM5_SDESN+ZM5_LAD+ZM5_APD+ZM5_CTD)/100 VALOR
	FROM %Table:SD3% SD3, %Table:SD1% SD1, %Table:ZM5% ZM5
	WHERE SD3.D_E_L_E_T_ = ' '
	AND SD1.D_E_L_E_T_ = ' '
	AND ZM5.D_E_L_E_T_ = ' '
	AND D3_FILIAL = %xFilial:SD3%
	AND D3_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	AND D3_CHAVEF1 <> ' '
	AND D3_I_ORIGE = 'DESCTETRAE'
	AND D3_ESTORNO <> 'S'
	AND ZM5_FILIAL = %xFilial:ZM5%
	AND D1_COD = ZM5_PRODUT
	AND D1_FILIAL = D3_FILIAL
	%exp:_cCFOPE%
	AND D1_EMISSAO BETWEEN ZM5_DTINI AND ZM5_DTFIM
	AND D1_FORNECE = 'F00004'
	AND D1_TIPO = 'N'
	AND D1_DOC||D1_SERIE||D1_FORNECE||D1_LOJA||D1_COD||D1_ITEM = TRIM(D3_CHAVEF1)
	AND D3_CUSTO1 <> Round(D1_CUSTO*(ZM5_AVD+ZM5_QSR+ZM5_SDESN+ZM5_LAD+ZM5_APD+ZM5_CTD)/100,%exp:_cDecimal%)
	UNION ALL
	SELECT SD3.R_E_C_N_O_ RECNO, D2_CUSTO1*(ZM5_AVD+ZM5_QSR+ZM5_SDESN+ZM5_LAD+ZM5_APD+ZM5_CTD)/100 VALOR
	FROM %Table:SD3% SD3, %Table:SD2% SD2, %Table:ZM5% ZM5, %Table:SD1% SD1
	WHERE SD3.D_E_L_E_T_ = ' '
	AND SD2.D_E_L_E_T_ = ' '
	AND ZM5.D_E_L_E_T_ = ' '
	AND SD1.D_E_L_E_T_ = ' '
	AND D1_FILIAL = D2_FILIAL
	AND D1_DOC = D2_NFORI
	AND D1_SERIE = D2_SERIORI
	AND D1_ITEM = D2_ITEMORI
	AND D1_FORNECE = D2_CLIENTE
	AND D1_LOJA = D2_LOJA
	AND D3_FILIAL = %xFilial:SD3%
	AND D3_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	AND D3_CHAVEF2 <> ' '
	AND D3_I_ORIGE = 'DESCTETRAS'
	AND D3_ESTORNO <> 'S'
	AND ZM5_FILIAL = %xFilial:ZM5%
	AND D2_COD = ZM5_PRODUT
	AND D2_FILIAL = D3_FILIAL
	%exp:_cCFOPS%
	AND D1_EMISSAO BETWEEN ZM5_DTINI AND ZM5_DTFIM
	AND D2_CLIENTE = 'F00004'
	AND D2_TIPO = 'N'
	AND D2_DOC||D2_SERIE||D2_CLIENTE||D2_LOJA||D2_COD||D2_ITEM = TRIM(D3_CHAVEF2)
	AND D3_CUSTO1 <> Round(D2_CUSTO1*(ZM5_AVD+ZM5_QSR+ZM5_SDESN+ZM5_LAD+ZM5_APD+ZM5_CTD)/100,%exp:_cDecimal%)
EndSql

COUNT TO _nQtdReg
(_cAlias)->(DBGoTop())
_oSelf:SetRegua1(_nQtdReg)

While !(_cAlias)->(Eof())
	_oSelf:IncRegua1("Atualizando custo....")
	SD3->(DBGoTo((_cAlias)->RECNO))
	SD3->(RecLock("SD3",.F.)) 
		SD3->D3_CUSTO1 := Round((_cAlias)->VALOR,_nDecimal)
		SD3->D3_CUSTO2 := xMoeda(SD3->D3_CUSTO1,1,2,SD3->D3_EMISSAO)
		SD3->D3_CUSTO3 := xMoeda(SD3->D3_CUSTO1,1,3,SD3->D3_EMISSAO)
		SD3->D3_CUSTO4 := xMoeda(SD3->D3_CUSTO1,1,4,SD3->D3_EMISSAO)
		SD3->D3_CUSTO5 := xMoeda(SD3->D3_CUSTO1,1,5,SD3->D3_EMISSAO)
	SD3->(MSUnLock())  
	(_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

Return
