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
Programa----------: MCOM021
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 16/11/2023
Descrição---------: Rotina para exportar os XMLs escriturados e recebidos pelo TOTVS Colaboração. Chamado 45591
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM021()

Local _cPerg		:= "MCOM021"
Local _oSelf		:= nil

//Cria interface principal
tNewProcess():New(	_cPerg											,; // Função inicial
					"Exporta XMLs"							,; // Descrição da Rotina
					{|_oSelf| MCOM021P(_oSelf) }					,; // Função do processamento
					"Essa rotina permite exportar os XMLs escriturados e recebidos pelo TOTVS Colaboração.",; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .T.                                              ) // Se .T. cria apenas uma regua de processamento.

Return

/*
===============================================================================================================================
Programa----------: MGLT021P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 16/11/2023
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM021P(_oSelf)

Local _cAlias   := GetNextAlias()
Local _cDestino := AllTrim(MV_PAR11)
Local _oFile 	As Object
Local _nCountRec:= 1
Local _aSelFil	:= {}
Local _cFiltro  := '%'

_oSelf:SetRegua1(2)
_oSelf:IncRegua1("Consultando registros no Banco de Dados")
//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SF1")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf
_cFiltro += GetRngFil( _aSelFil, "SF1", .T.,)
If MV_PAR10 == 1
    _cFiltro += " AND F1_ESPECIE = 'SPED' "
ElseIf MV_PAR10 == 2
    _cFiltro += " AND F1_ESPECIE = 'CTE' "
EndIf
_cFiltro += ' %'

BeginSql alias _cAlias
    SELECT F1_CHVNFE, F1_ESPECIE, Case WHEN CKO_I_ALTX = 'N' THEN CKO_XMLRET Else CKO_I_ORIG END CKO_XMLRET
    FROM %Table:CKO% CKO, %Table:SF1% SF1
    WHERE F1_FILIAL %Exp:_cFiltro%
    AND F1_FILIAL = CKO_FILPRO
    AND F1_CHVNFE = SubStr(CKO_ARQUIV,4,44)
    AND F1_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
    AND F1_DTDIGIT BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
    AND F1_FORNECE BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
    AND F1_LOJA BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
    AND F1_STATUS = 'A'
    AND CKO.D_E_L_E_T_ = ' '
    AND SF1.D_E_L_E_T_ = ' '
EndSql

Count To _nCountRec
(_cAlias)->( DBGoTop() )

While (_cAlias)->(!Eof())

    _oSelf:SetRegua1(_nCountRec)
    _oSelf:IncRegua1("Gerando arquivo...")

    _oFile:= FWFileWriter():New(_cDestino+(_cAlias)->F1_CHVNFE+".xml")
    _oFile:SetEncodeUTF8(.T.)
    If _oFile:Create()
        _oFile:Write(AllTrim((_cAlias)->CKO_XMLRET))
        _oFile:Close()
        If !_oFile:Exists()
            MsgStop("Erro na gravação do arquivo XML: "+(_cAlias)->F1_CHVNFE+". Ele será ignorado. Erro: "+ _oFile:Error():Message,"MCOM02101")
        EndIf
    Else
        MsgStop("Erro na criação do arquivo XML: "+(_cAlias)->F1_CHVNFE+". Ele será ignorado. Erro: "+ _oFile:Error():Message,"MCOM02102")
    EndIf
    FreeObj(_oFile)
    (_cAlias)->(DBSkip())
EndDo

Return
