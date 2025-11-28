/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |01/08/2025| Chamado 51453. Substituir função EncodeUtf8 por FWHttpEncode
Lucas Borges  |19/08/2025| Chamado 51840. Ajustado para não enviar e-mail para o sistema quando For um Admin
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "msgraphi.ch"
#Include 'XMLXFUN.ch'
#Include 'FileIO.ch'

/*
===============================================================================================================================
Programa----------: GLTXFUN
Autor-------------: Alexandre Villar
Data da Criacao---: 11/07/2014
Descrição---------: Rotinas genéricas para utilização nos desenvolvimentos para o Módulo GLT
===============================================================================================================================
*/

/*
===============================================================================================================================
Programa----------: ChkRetir
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar retiro e loja na tela de recepcao de leite. X3_VLDUSER
Parametros--------: _cAlias -> C -> Tabela que deve ser validada (ZLD/ZLW)
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ChkRetir(_cAlias As Character)

Local _aArea	:= FWGetArea() As Array
Local _cVar		:= ReadVar() As Character
Local _cCodigo	:= &( _cVar ) As Character
Local _cRetiro	:= '' As Character
Local _lRet		:= .F. As Logical

If !Empty( _cCodigo )
	
	// Valida Retiro e Loja
	DBSelectArea("SA2")
	SA2->( DBSetOrder(1) )
	// Se estiver validando ZLW_RETIRO
	If Upper( AllTrim( _cVar ) ) == "M->"+_cAlias+"_RETIRO"
		If IsDigit( _cCodigo )
			_cCodigo := 'P' + PadL(AllTrim(_cCodigo),GetSX3Cache(_cAlias+"_RETIRO","X3_TAMANHO")-1,"0")
		EndIf
		_lRet := SA2->( DBSeek( xFilial("SA2") + _cCodigo ) )
	ElseIf Upper( AllTrim( _cVar ) ) == "M->"+_cAlias+"_RETILJ"
	    _cCodigo := PadL(AllTrim(_cCodigo),GetSX3Cache(_cAlias+"_RETILJ","X3_TAMANHO"),"0")
		_cRetiro	:= aCols[n][ aScan( aHeader , {|x| AllTrim(x[2]) == ""+_cAlias+"_RETIRO" } ) ]
		_lRet		:= SA2->( DBSeek( xFilial("SA2") + _cRetiro + _cCodigo ) )
	EndIf
	
	If !_lRet
		FWAlertError("Código de retiro inexistente. Insira um código de retiro válido!","GLTXFUN003")
	EndIf

EndIf

If _lRet
	aCols[n][ aScan( aHeader , {|x| AllTrim(x[2]) == _cAlias+"_RETIRO" } ) ] := SA2->A2_COD
	aCols[n][ aScan( aHeader , {|x| AllTrim(x[2]) == _cAlias+"_RETILJ" } ) ] := SA2->A2_LOJA
	aCols[n][ aScan( aHeader , {|x| AllTrim(x[2]) == _cAlias+"_DCRRET" } ) ] := SA2->A2_NOME
EndIf

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: ChkReg
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 15/08/2019
Descrição---------: Verifica se existe registro em tabela conforme parâmetros informados. Útil quando não existe índice
Parametros--------: _cTabela -> C -> Alias a ser buscado
					_cFiltro -> C -> Filtro para validação
Retorno-----------: lRet -> L -> .F. Encontrou registros / .T. Não encontrou registros
===============================================================================================================================
*/
User Function ChkReg(_cTabela As Character,_cFil As Character)

Local _cFiltro	:= "% AND "+_cFil+" %" As Character
Local _cFrom	:= "%"+RetSqlName(_cTabela)+" %" As Character
Local _cAlias	:= GetNextAlias() As Character
Local _lRet		:= .T. As Logical

BeginSql alias _cAlias
	SELECT COUNT(1) CONT
	  FROM %exp:_cFrom%
	 WHERE D_E_L_E_T_ = ' '
	    %exp:_cFiltro%
EndSql

If (_cAlias)->CONT > 0
	FWAlertWarning("Esse registros possui vínculo na tabela "+_cTabela+" - "+FwSX2Util():GetX2Name(_cTabela)+" e não poderá ser excluído. "+;
	"Elimine o vínculo e o registro poderá ser excluído.","GLTXFUN005")
	_lRet := .F.
EndIf
(_cAlias)->( DBCloseArea() )

Return(_lRet)

/*
===============================================================================================================================
Programa----------: showMemo
Autor-------------: Microsiga
Data da Criacao---: 26/09/2008
Descrição---------: Tratativa para conteúdo de campos memos
Parametros--------: ex_string	: Conteúdo do Campo
------------------: ex_largura	: Configuração do Campo
Retorno-----------: ex_array	: array com o conteúdo do campo
===============================================================================================================================
*/
User Function showMemo( ex_string As Character, ex_largura As Numeric)

Local ex_pos 	:= 0 As Numeric
Local ex_array  := {} As Array
Local ex_letra  := "" As Character
Local ex_linha  := "" As Character
Local ex_aux    := "" As Character
Local _nX		:= 0 As Numeric

ex_string := AllTrim(ex_string)

For _nX:=1 To Len(ex_string)
	
	ex_letra := SubStr(ex_string,_nX,1)
	ex_aux   := SubStr(ex_string,_nX,1)
	
	ex_letra := StrTran(ex_letra,char(13),"")
	ex_letra := StrTran(ex_letra,char(10),"")
	
	ex_linha += ex_letra
	
	ex_pos++
	If ((ex_pos > ex_largura) .Or. (ex_aux == char(13))) .And. (ex_letra == " ")
		aAdd(ex_array,ex_linha)
		ex_linha  := ""
		ex_pos := 0
	EndIf
	
Next _nX

aAdd(ex_array,ex_linha)

Return( ex_array )

/*
===============================================================================================================================
Programa----------: VolLeite
Autor-------------: Renato
Data da Criacao---: 05/11/2008
Descrição---------: Retorna volume de leite (ZL8)
Parametros--------: _cFilAux	: Filial
------------------: _dDtIni		: Data Inicial
------------------: _dDtFim		: Data Final
------------------: _cSetor		: Código do Setor
------------------: _cLinRot	: Linha/Rota
------------------: _cCodFor 	: Fornecedor
------------------: _cLojFor	: Loja do Fornecedor
------------------: _cTipoLR	: Tipo L=Linha ou R=Rota //uso descontinuado, mantido por compatibilidade
------------------: _nOpc		: Tipo de Leite: 1 = Produtor / 2 = Cooperativa
Retorno-----------: _nTotal	: Total do volume de leite
===============================================================================================================================
*/
User Function VolLeite(_cFilAux As Character, _dDtIni As Date, _dDtFim As Date, _cSetor As Character, _cLinRot As Character,;
					 _cCodFor As Character, _cLojFor As Character, _cTipoLR As Character, _nOpc As Numeric, _nTitular As Numeric)

Local _aArea	:= FWGetArea() As Array
Local _cAlias	:= GetNextAlias() As Character
Local _cFiltro	:= "%" As Character
Local _cCampos	:= "%" As Character
Local _cTable 	:= "%" As Character
Local _cAux		:= "ZLD" As Character
Local _nTotal	:= 0 As Numeric

Default _nOpc	 := 1
Default _nTitular:= 1

If _nOpc == 2
	_cAux := 'ZLW'
EndIf
_cCampos += " SUM("+ _cAux +"_QTDBOM) TBOM %"
_cTable += RetSqlName(_cAux) +" %"
_cFiltro += " AND "+ _cAux +"_DTCOLE BETWEEN '"+ DToS(_dDtIni) +"' AND '"+ DToS(_dDtFim) +"' "
_cFiltro += " AND "+ _cAux +"_FILIAL     = '"+ _cFilAux +"' "
_cFiltro += IIf( Empty( _cSetor  ) , '' , " AND "+ _cAux +"_SETOR  = '"+ _cSetor  +"' " )
_cFiltro += IIf( Empty( _cLinRot ) , '' , " AND "+ _cAux +"_LINROT = '"+ _cLinRot +"' " )
If _nTitular == 1
	_cFiltro += IIf( Empty( _cCodFor ) , '' , " AND A2_COD = '"+ _cCodFor +"' " )
	_cFiltro += IIf( Empty( _cLojFor ) , '' , " AND A2_LOJA = '"+ _cLojFor +"' " )
Else
	_cFiltro += IIf( Empty( _cCodFor ) , '' , " AND A2_L_TANQ = '"+ _cCodFor +"' " )
	_cFiltro += IIf( Empty( _cLojFor ) , '' , " AND A2_L_TANLJ = '"+ _cLojFor +"' " )
EndIf
_cFiltro += " AND "+ _cAux +"_RETIRO     = A2_COD"
_cFiltro += " AND "+ _cAux +"_RETILJ     = A2_LOJA"

_cFiltro += "%"

BeginSql alias _cAlias
	SELECT %exp:_cCampos%
	  FROM %exp:_cTable% X, %Table:SA2% SA2
	 WHERE X.D_E_L_E_T_ = ' '
	 AND SA2.D_E_L_E_T_ = ' '
	   %exp:_cFiltro%
EndSql

If (_cAlias)->( !Eof() )
	_nTotal  := (_cAlias)->TBOM
EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return(_nTotal)

/*
===============================================================================================================================
Programa----------: GetKM
Autor-------------: Abrahao P. Santos
Data da Criacao---: 02/12/2008
Descrição---------: Funcao usada para retornar o KM rodado pelo Fretista no período indicado (ZL8)
Parametros--------: _cFilial - Filial a ser verificada
------------------: _cSetor  - Setor a ser considerado
------------------: _cLinha  - Linha a ser considerada
------------------: _cFretis - Código do Fretista
------------------: _cFretLj - Loja do Fretista
------------------: _dDtIni  - Data Inicial do período
------------------: _dDtFim  - Data Final do período
------------------: _cVeiculo- Codigo de Veiculo
------------------: _lPorVaigem - Devolve uma lista de km por viagens
Retorno-----------: _nKMRet  - Quantidade de KM  OU _aViagens
===============================================================================================================================
*/
User Function GetKM(_cFilial As Character, _cSetor As Character, _cLinha As Character, _cFretis As Character, _cFretLj As Character,;
					 _dDtIni As Date, _dDtFim As Date, _cVeiculo As Character, _lPorVaigem As Logical)

Local _aArea	:= FWGetArea() As Array
Local _nKmRet	:= 0 As Numeric
Local _cQuery	:= '' As Character
Local _cAlias	:= GetNextAlias() As Character
Local _aViagens := {} As Array

If ValType(_lPorVaigem) <> "L"
   _lPorVaigem:=.F.
EndIf

If _lPorVaigem
   _cQuery := ""
Else
   _cQuery := " SELECT NVL( SUM( KM ) , 0 ) AS KM FROM( "
EndIf

_cQuery += "  SELECT ZLD.ZLD_TICKET , ZLD.ZLD_KM AS KM "
_cQuery += "       FROM "+ RetSqlName('ZLD') +" ZLD "
_cQuery += "       WHERE "
_cQuery += "           ZLD.D_E_L_E_T_ = ' ' 
_cQuery += "       AND ZLD.ZLD_FILIAL = '"+ _cFilial +"' "
_cQuery += "       AND ZLD.ZLD_SETOR  = '"+ _cSetor  +"' "
_cQuery += "       AND ZLD.ZLD_LINROT = '"+ _cLinha  +"' "
_cQuery += "       AND ZLD.ZLD_DTCOLE BETWEEN '"+ DToS( _dDtIni ) +"' AND '"+ DToS( _dDtFim ) +"' AND ZLD.ZLD_KM > 0 "

If !Empty(_cFretis)
   _cQuery += "    AND ZLD.ZLD_FRETIS = '"+ _cFretis +"' "
EndIf
If !Empty(_cFretLj)
   _cQuery += "    AND ZLD.ZLD_LJFRET = '"+ _cFretLj +"' "
EndIf
If _cVeiculo <> NIL .And. !Empty(_cVeiculo)
   _cQuery += "    AND ZLD.ZLD_VEICUL = '"+ _cVeiculo +"' "
EndIf

_cQuery += "GROUP BY ZLD.ZLD_TICKET, ZLD.ZLD_CODREC, ZLD.ZLD_KM "

If !_lPorVaigem
   _cQuery += ") TAB "
EndIf
_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAlias)

(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
   _nKmRet += (_cAlias)->KM
   If _lPorVaigem
	  aAdd(_aViagens,{(_cAlias)->ZLD_TICKET,(_cAlias)->KM})
   EndIf
  (_cAlias)->(DBSkip())
EndDo
	
(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

If _lPorVaigem
   Return _aViagens
EndIf

Return(_nKmRet)

/*
===============================================================================================================================
Programa----------: getSeqZLF
Autor-------------: Abrahao P. Santos
Data da Criacao---: 01/12/2008
Descrição---------: Retorna ultimo numero da sequencia da ZLF 
Parametros--------: cMix,cEvento,cProd,cLj
Retorno-----------: cseq -> próxima sequencia a utiliar
===============================================================================================================================
*/
User Function getSeqZLF(cMix As Character,cEvento As Character,cProd As Character,cLj As Character)

Local _aArea	:= FWGetArea() As Array
Local _cSeq		:= "" As Character
Local _cAlias	:= GetNextAlias() As Character

BeginSql alias _cAlias
	SELECT NVL(MAX(ZLF_SEQ),'000') SEQ
	  FROM %Table:ZLF%
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLF_CODZLE = %exp:cMix%
	   AND ZLF_A2COD = %exp:cProd%
	   AND ZLF_A2LOJA = %exp:cLj%
EndSql

_cSeq := Soma1((_cAlias)->SEQ)
(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return _cSeq

/*
===============================================================================================================================
Programa----------: GetDiaFrt
Autor-------------: Abrahao P. Santos
Data da Criacao---: 01/12/2008
Descrição---------: Funcao usada para retornar a quantidade de dias trabalhados pelo Fretista (ZL8)
Parametros--------: _cFilial - Filial a ser verificada
------------------: _cSetor  - Setor a ser considerado
------------------: _cLinha  - Linha a ser considerada
------------------: _cFretis - Código do Fretista
------------------: _cFretLj - Loja do Fretista
------------------: _dDtIni  - Data Inicial
------------------: _dDtFim  - Data Final
Retorno-----------: _nDias   - Quantidade de Dias
===============================================================================================================================
*/
User Function GetDiaFrt(_cFilial As Character,_cSetor As Character,_cLinha As Character,_cFretis As Character,_cFretLj As Character,_dDtIni As Date,_dDtFim As Date)

Local _aArea	:= FWGetArea() As Array
Local _nDias	:= 0 As Numeric
Local _cAlias	:= GetNextAlias() As Character

BeginSql alias _cAlias
	SELECT COUNT(1) COUNT
	  FROM (SELECT ZLD.ZLD_DTCOLE
	          FROM %Table:ZLD% ZLD
	         WHERE ZLD.D_E_L_E_T_ = ' '
	           AND ZLD.ZLD_FILIAL = %exp:_cFilial%
	           AND ZLD.ZLD_SETOR = %exp:_cSetor%
	           AND ZLD.ZLD_LINROT = %exp:_cLinha%
	           AND ZLD.ZLD_FRETIS = %exp:_cFretis%
	           AND ZLD.ZLD_LJFRET = %exp:_cFretLj%
	           AND ZLD.ZLD_DTCOLE BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
	         GROUP BY ZLD.ZLD_DTCOLE) TAB
EndSql

_nDias := (_cAlias)->COUNT

(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return(_nDias)

/*
===============================================================================================================================
Programa----------: VolFret
Autor-------------: Abrahao P. Santos
Data da Criacao---: 11/12/2008
Descrição---------: Funcao usada para retornar o volume movimentado pelo Fretista para o MIX/Setor/Linha informados
Parametros--------: _cFilial - Filial a ser verificada
------------------: _cSetor  - Setor a ser considerado
------------------: _cLinha  - Linha a ser considerada
------------------: _cFretis - Código do Fretista
------------------: _cFretLj - Loja do Fretista
------------------: _dDtIni  - Data inicial do período
------------------: _dDtFim  - Data final do período
------------------: _cVeiculo- Codigo de Veiculo
Retorno-----------: _nVolume - Volume Total
===============================================================================================================================
*/
User Function VolFret(_cFilial As Character,_cSetor As Character,_cLinha As Character,_cFretis As Character,_cFretLj As Character,_dDtIni As Date,_dDtFim As Date,_cVeiculo As Character)

Local _aArea	:= FWGetArea() As Array
Local _nVolume	:= 0 As Numeric
Local _cFiltro	:= "%" As Character
Local _cAlias	:= GetNextAlias() As Character

If !Empty(_cLinha)
   _cFiltro += " AND ZLD.ZLD_LINROT = '"+ _cLinha  +"' "
EndIf
If ValType(_cVeiculo) = "C" .And. !Empty(_cVeiculo)
   _cFiltro += " AND ZLD.ZLD_VEICUL = '"+ _cVeiculo +"' "
EndIf
_cFiltro += "%"

BeginSql alias _cAlias
	SELECT NVL(SUM(ZLD_QTDBOM),0) VOLUME
	  FROM %Table:ZLD% ZLD
	 WHERE ZLD.D_E_L_E_T_ = ' '
	   %exp:_cFiltro%
	   AND ZLD.ZLD_FILIAL = %exp:_cFilial%
	   AND ZLD.ZLD_SETOR = %exp:_cSetor%
	   AND ZLD.ZLD_FRETIS = %exp:_cFretis%
	   AND ZLD.ZLD_LJFRET = %exp:_cFretLj%
	   AND ZLD.ZLD_DTCOLE BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
EndSql

_nVolume := (_cAlias)->VOLUME
(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return(_nVolume)

/*
===============================================================================================================================
Programa----------: VFrete
Autor-------------: Abrahao P. Santos
Data da Criacao---: 11/12/2008
Descrição---------: Funcao usada para retornar o volume de leite movimentado do Fretista para o MIX/Setor/Linha posicionados (ZL8)
Parametros--------: _cVeiculo- Codigo de Veiculo
Retorno-----------: _nValFRT
===============================================================================================================================
*/
User Function VFrete(_cVeiculo As Character)

Local _nVolFRT := U_VolFret( xFilial("ZL8") , ZL2->ZL2_COD , ZL3->ZL3_COD , SA2->A2_COD , SA2->A2_LOJA , ZLE->ZLE_DTINI , ZLE->ZLE_DTFIM , _cVeiculo ) As Numeric

Return(_nVolFRT)

/*
===============================================================================================================================
Programa----------: PagtoQual
Autor-------------: Abrahao P. Santos
Data da Criacao---: 11/12/2008
Descrição---------: Retorna valor da bonificacao por qualidade (ZL8)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function PagtoQual(_cTipo As Character,_cCodigo As Character,_nMeses As Numeric)

Local _nVlrInd	:= 0 As Numeric
Local _nVlrFxa	:= 0 As Numeric
Local _nTotal	:= 0 As Numeric
Local _nVolume	:= 0 As Numeric
Local _cAlias	:= GetNextAlias() As Character
Local _dDtIni	:= SToD('') As Date
Local _nValMin	:= 0 As Numeric
Local _cRound	:= "% "+cValToChar(IIf(_cTipo=='E',4,2))+" %" As Character
Local _cFiltro	:= "% " As Character
Default _nMeses	:= 3
Default _cCodigo := ""

If ValType( _nMeses ) <> "N" .Or. _nMeses <= 0
	_nMeses := 3
EndIf

_dDtIni := FirstDay(MonthSub(ZLE->ZLE_DTFIM,(_nMeses-1)))
//====================================================================================================
//Materia Gorda por Viagem
//====================================================================================================
If _cTipo = 'V'
	BeginSql alias _cAlias
		SELECT Round(SUM(EXCEDENTE), 2) TOTAL
			FROM (SELECT (NVL(Round((SELECT SUM(ZAP_GORD) / COUNT(1)
                            FROM %Table:ZAP% AP2
                           WHERE AP2.D_E_L_E_T_ = ' '
                             AND AP2.ZAP_FILIAL = ZLX.ZLX_FILIAL
                             AND ZLX.ZLX_CODANA = AP2.ZAP_CODIGO),
                          2),
                    0) /*MEDIA_MG*/
               - (SELECT MIN(ZLAA.ZLA_FXFIM)
                     FROM %Table:ZLA% ZLAA
                    WHERE ZLAA.ZLA_FILIAL = ZLX.ZLX_FILIAL
                      AND ZLAA.ZLA_SETOR = ZLD_SETOR
                      AND ZLX.ZLX_DTENTR BETWEEN ZLAA.ZLA_DTINI AND
                          ZLAA.ZLA_DTFIM
                      AND ZLAA.ZLA_MATGOR = '1'
                      AND ZLAA.D_E_L_E_T_ = ' ') /*EXCEDENTE*/
               ) * ZLD_QTDBOM / 100 * ZLA_VALOR EXCEDENTE
          FROM %Table:ZLX% ZLX, %Table:ZLD% ZLD, %Table:ZLA% ZLA
         WHERE ZLX.D_E_L_E_T_ = ' '
           AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
           AND ZLX.ZLX_TIPOLT = 'P'
           AND ZLD.D_E_L_E_T_ = ' '
           AND ZLD.ZLD_FILIAL = ZLX.ZLX_FILIAL
           AND ZLD.ZLD_TICKET = ZLX.ZLX_TICKET
           AND ZLD.ZLD_SETOR = ZLX.ZLX_SETOR
           AND ZLD.ZLD_RETIRO <> ' '
           AND ZLD.ZLD_RETIRO = %exp:SA2->A2_COD%
           AND ZLD.ZLD_RETILJ = %exp:SA2->A2_LOJA%
           AND ZLA.ZLA_FILIAL = ZLX.ZLX_FILIAL
           AND ZLA.ZLA_SETOR = ZLX.ZLX_SETOR
           AND COALESCE(Round((SELECT SUM(ZAP_GORD) / COUNT(1)
                                FROM %Table:ZAP% AP2
                               WHERE AP2.D_E_L_E_T_ = ' '
                                 AND AP2.ZAP_FILIAL = ZLX.ZLX_FILIAL
                                 AND ZLX.ZLX_CODANA = AP2.ZAP_CODIGO),
                              2),
                        0) BETWEEN ZLA_FXINI AND ZLA_FXFIM
           AND ZLX.ZLX_DTENTR BETWEEN ZLA.ZLA_DTINI AND ZLA.ZLA_DTFIM
           AND ZLA.ZLA_MATGOR = '1'
           AND ZLA.D_E_L_E_T_ = ' '
           AND ZLX.ZLX_DTENTR BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%)
	EndSql

	_nTotal := (_cAlias)->TOTAL
	(_cAlias)->( DBCloseArea() )
Else
	If _cTipo == "E"
		_cFiltro += " AND ZLB.ZLB_LINROT = '" + ZL3->ZL3_COD + "' "
	EndIf
	_cFiltro += " %"
	//====================================================================================================
	// Consulta para obter a média do índice por tipo de faixa
	//====================================================================================================
	BeginSql alias _cAlias
		SELECT Round(DECODE(ZL9_MEDIA,'G',POWER(EXP(SUM(LN(ZLB_VLRFX))), (1 / COUNT(ZLB_VLRFX))),
							AVG(ZLB_VLRFX)),%exp:_cRound%) AS TOTAL
		FROM %Table:ZLB% ZLB, %Table:ZL9% ZL9
		WHERE ZLB.D_E_L_E_T_ = ' '
			AND ZL9.D_E_L_E_T_ = ' '
			AND ZLB.ZLB_FILIAL = %xFilial:ZLB%
			AND ZL9.ZL9_FILIAL = %xFilial:ZL9%
			AND ZLB.ZLB_SETOR = %exp:ZL2->ZL2_COD%
			AND ZLB.ZLB_TIPOFX = %exp:_cCodigo%
			AND ZLB.ZLB_RETIRO = %exp:SA2->A2_COD%
			AND ZLB.ZLB_RETILJ = %exp:SA2->A2_LOJA%
			AND ZLB.ZLB_DATA BETWEEN %exp:_dDtIni% AND %exp:ZLE->ZLE_DTFIM%
			AND ZLB.ZLB_VLRFX > 0
			%exp:_cFiltro%
			AND ZLB.ZLB_TIPOFX = ZL9.ZL9_COD
		GROUP BY ZL9_MEDIA
	EndSql

	If (_cAlias)->( !Eof() )
		_nVlrInd := (_cAlias)->TOTAL
	EndIf
	(_cAlias)->( DBCloseArea() )

	//====================================================================================================
	// Consulta para obter o valor atribuído ao índice de acordo com as faixas
	//====================================================================================================
	If _cTipo <> 'E'
		BeginSql alias _cAlias
			SELECT NVL(ZLA_VALOR,0) VALOR
			FROM %Table:ZLA%
			WHERE D_E_L_E_T_ = ' '
			AND ZLA_FILIAL = %xFilial:ZLA%
			AND ZLA_SETOR = %exp:ZL2->ZL2_COD%
			AND ZLA_COD = %exp:_cCodigo%
			AND ZLA_FXINI <= %exp:_nVlrInd%
			AND ZLA_FXFIM >= %exp:_nVlrInd%
		EndSql

		If (_cAlias)->( !Eof() )
			_nVlrFxa := (_cAlias)->VALOR
		EndIf
		(_cAlias)->( DBCloseArea() )
	EndIf
	//====================================================================================================
	// Evento de Crédito
	//====================================================================================================
	If _cTipo == "C"
		If _nVlrFxa > 0
			_nVolume	:= U_VOLLEITE(CFILANT,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,SA2->A2_LOJA,,,1)-U_DESCLEIT()
			_nTotal		+= _nVlrFxa * _nVolume
		EndIf

	//====================================================================================================
	// Evento de Débito
	//====================================================================================================
	ElseIf _cTipo == "D"
		If _nVlrFxa < 0
			_nVolume	:= U_VOLLEITE(CFILANT,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,SA2->A2_LOJA,,,1)-U_DESCLEIT()
			_nTotal		+= _nVlrFxa * _nVolume
		EndIf

	//====================================================================================================
	// Evento de Crédito Matéria gorda
	//====================================================================================================
	ElseIf _cTipo == "G"
		If _nVlrFxa > 0
			BeginSql alias _cAlias
				SELECT ZLA_FXINI VALOR
				FROM %Table:ZLA%
				WHERE D_E_L_E_T_ = ' '
				AND ZLA_FILIAL = %xFilial:ZLA%
				AND ZLA_SETOR = %exp:ZL2->ZL2_COD%
				AND ZLA_COD = %exp:_cCodigo%
				ORDER BY ZLA_FXINI
				FETCH FIRST 1 ROWS ONLY
			EndSql
			_nValMin := (_cAlias)->VALOR
			(_cAlias)->(DBCloseArea())
			_nVolume	:= U_VOLLEITE(CFILANT,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,SA2->A2_LOJA,,,1)-U_DESCLEIT()
			_nTotal		+= _nVlrFxa *(((_nVlrInd-_nValMin)* _nVolume)/100)
		EndIf

	ElseIf _cTipo == "E"
		_nVolume	:= U_VOLLEITE(CFILANT,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,SA2->A2_LOJA,,,1)-U_DESCLEIT()
		_nTotal		:= _nVlrInd*_nVolume
	EndIf
EndIf

Return(_nTotal)

/*
===============================================================================================================================
Programa----------: VlrDesvio
Autor-------------: Abrahao P. Santos
Data da Criacao---: 18/12/2008
Descrição---------: Funcao usada para retornar o valor do desvio de rota realizado por um Fretista (ZL8)
Parametros--------: _cTipPag - Todas as tabelas já estão posicionadas na geração de eventos do MIX
Retorno-----------: _nRet - Valor do desvio
===============================================================================================================================
*/
User Function VlrDesvio(_cTipPag As Character)

Local _cFiltro	:= "%" As Character
Local _cAlias	:= GetNextAlias() As Character
Local _nRet		:= 0 As Numeric

// Obtem valor total dos desvios do Fretista
If !Empty( _cTipPag )
	_cFiltro += " AND ZLC.ZLC_FORPAG = '"+ _cTipPag +"' "
EndIf
_cFitlro += "%"
BeginSql alias _cAlias
	SELECT NVL(Round(SUM(TOTAL),2),0) TOTAL
	  FROM (SELECT (ZLC.ZLC_QTD * ZLC.ZLC_VALOR) TOTAL
	          FROM %Table:ZLC% ZLC
	         WHERE ZLC.D_E_L_E_T_ = ' '
	           %exp:_cFiltro%
	           AND ZLC.ZLC_FILIAL = %exp:cFilAnt%
	           AND ZLC.ZLC_SETOR = %exp:ZL2->ZL2_COD%
	           AND ZLC.ZLC_LINROT = %exp:ZL3->ZL3_COD%
	           AND ZLC.ZLC_FRETIS = %exp:SA2->A2_COD%
	           AND ZLC.ZLC_LJFRET = %exp:SA2->A2_LOJA%
	           AND ZLC.ZLC_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%)
EndSql

_nRet := (_cAlias)->TOTAL
(_cAlias)->( DBCloseArea() )

Return(_nRet)

/*
===============================================================================================================================
Programa----------: FaltaLeite
Autor-------------: Abrahao P. Santos
Data da Criacao---: 18/12/2008
Descrição---------: Retorna linha com maior volume de leite (ZL8)
Parametros--------: cpFretis - fretista
					_cLoja - loja do fretista
					dpDt1 - data inicial de coleta
					dpDt2 - data final de coleta
Retorno-----------: clin - Linha com maior volume no período
===============================================================================================================================
*/
User Function FaltaLeite(_cSetor As Character,_cLinha As Character,cpFretis As Character,_cLoja As Character,dt1 As Date,dt2 As Date)

Local _nRet :=0 As Numeric
Local _cAlias := "" As Character

If AllTrim(_cLinha) != AllTrim(LinMaxRec(cpFretis,_cLoja,dt1,dt2))
	Return _nRet
EndIf

_cAlias := GetNextAlias()

BeginSql alias _cAlias
	SELECT NVL(SUM(VOLUME), 0) VOLUME
	  FROM (SELECT ZLD_TICKET,
	               MAX(ZLD_DTCOLE) DTCOLETA,
	               MAX(ZLD_TOTBOM) - SUM(ZLD_QTDBOM) VOLUME
	          FROM %Table:ZLD% ZLD
	         WHERE D_E_L_E_T_ = ' '
	           AND ZLD_DTCOLE BETWEEN %exp:dt1% AND %exp:dt2%
	           AND ZLD_SETOR = %exp:_cSetor%
	           AND ZLD_FRETIS = %exp:cpFretis%
	           AND ZLD_LJFRET = %exp:_cLoja%
	           AND ZLD_FILIAL = %xFilial:ZLD%
	         GROUP BY ZLD_TICKET)
EndSql

_nRet := (_cAlias)->VOLUME
(_cAlias)->(DBCloseArea())

If _nRet < 0
	_nRet *= -1
Else
	_nRet := 0         
EndIf

Return( _nRet )

/*
===============================================================================================================================
Programa----------: getVolDay
Autor-------------: Abrahao P. Santos
Data da Criacao---: 18/12/2008
Descrição---------: Calcula volume de leite do dia
Parametros--------: _cProd - código do produtor
					_cLoja - loja do produtor
					_cDia - data do cálculo
Retorno-----------: nvalor - valor arredondado
===============================================================================================================================
*/
User Function getVolDay(_cProd As Character,_cLoja As Character,_cDia As Character)

Local _aArea	:= FWGetArea() As Array
Local _nRet		:= 0 As Numeric
Local _cAlias	:= GetNextAlias() As Character

BeginSql alias _cAlias
	SELECT NVL(SUM(ZLD_QTDBOM),0) VOLUME
	  FROM %Table:ZLD% ZLD
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLD_FILIAL = %xFilial:ZLD%
	   AND ZLD_RETIRO = %exp:_cProd%
	   AND ZLD_RETILJ = %exp:_cLoja%
	   AND ZLD_DTCOLE = %exp:_cDia%
EndSql

_nRet := (_cAlias)->VOLUME
(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return _nRet

/*
===============================================================================================================================
Programa----------: TXRESFRI
Autor-------------: Abrahao P. Santos
Data da Criacao---: 26/03/2009
Descrição---------: Retorna valor da taxa de resfriamento. Chamado no ZL8_FORMUL com todas as tabelas posicionadas
Parametros--------: Nenhum
Retorno-----------: Valor da Taxa
===============================================================================================================================
*/
User Function TXRESFRI

Local _aArea	:= FWGetArea() As Array
Local _nRet		:= 0 As Numeric
Local _cAlias	:= GetNextAlias() As Character

BeginSql alias _cAlias
	SELECT SA2.A2_COD, SA2.A2_LOJA, ZLD.ZLD_LINROT, SA2.A2_L_TXRES, SA2.A2_L_TPTXF
	  FROM %Table:SA2% SA2, %Table:ZLD% ZLD
	 WHERE SA2.D_E_L_E_T_ = ' '
	   AND ZLD.D_E_L_E_T_ = ' '
	   AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
	   AND SA2.A2_COD = ZLD.ZLD_RETIRO
	   AND SA2.A2_LOJA = ZLD.ZLD_RETILJ
	   AND SA2.A2_L_TANQ = %exp:SA2->A2_COD%
	   AND SA2.A2_L_TANLJ = %exp:SA2->A2_LOJA%
	   AND SA2.A2_L_TXRES <> 0
	   AND ZLD_SETOR = %exp:ZL2->ZL2_COD%
	   AND ZLD.ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
	 GROUP BY SA2.A2_COD, SA2.A2_LOJA, ZLD.ZLD_LINROT, SA2.A2_L_TXRES, SA2.A2_L_TPTXF
EndSql
While (_cAlias)->( !Eof() )
	If (_cAlias)->A2_L_TPTXF == 'L'
		_nRet += U_VolLeite(xFilial('ZLD'),ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,ZL2->ZL2_COD,(_cAlias)->ZLD_LINROT,(_cAlias)->A2_COD,(_cAlias)->A2_LOJA) * (_cAlias)->A2_L_TXRES
	Else
		_nRet += (_cAlias)->A2_L_TXRES
	EndIf
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return(_nRet)

/*
===============================================================================================================================
Programa----------: TXDSFRT
Autor-------------: Abrahao P. Santos
Data da Criacao---: 26/03/2009
Descrição---------: Funcao para retornar valor da taxa de Desconto de Frete do cadastro do Produtor posicionado (ZL8)
Parametros--------: Nenhum
Retorno-----------: _nRet - valor da taxa
===============================================================================================================================
*/
User Function TXDSFRT

Local _nRet := 0 As Numeric
Local _nVol := 0 As Numeric
Local _nVlr := 0 As Numeric

If SA2->A2_L_TPFRT == 'L' .And. SA2->A2_L_TXFRT <> 0
	//====================================================================================================
	// Calcula o Volume de Leite do Produtor vezes a porcentagem informada no cadastro
	//====================================================================================================
	_nVol := U_VolLeite( xFilial("ZLD") , ZLE->ZLE_DTINI , ZLE->ZLE_DTFIM , ZL2->ZL2_COD , ZL3->ZL3_COD , SA2->A2_COD , SA2->A2_LOJA )
	If _nVol == 0
		FWAlertWarning("Não foi gerada a Taxa de Desconto de Frete por não haver volume produzido pelo Produtor ["+ SA2->A2_COD +"] no MIX ["+ ZLE->ZLE_COD +"] na Linha ["+ ZL3->ZL3_COD +"].","GLTXFUN011")
	Else	
		_nRet := _nVol * SA2->A2_L_TXFRT
	EndIf
EndIf

If SA2->A2_L_TPFRT <> 'L' .And. SA2->A2_L_TXFRT <> 0
	//====================================================================================================
	// Calcula o Total pago ao produtor vezes a porcentagem informada no cadastro
	//====================================================================================================
	_nVlr := U_GetTotCr( xFilial("ZLF") , ZL2->ZL2_COD , ZL3->ZL3_COD , SA2->A2_COD , SA2->A2_LOJA , ZLE->ZLE_COD )
	If _nVlr == 0
		FWAlertWarning("Não foi gerada a Taxa de Desconto de Frete por não haver valor de Crédito para o Produtor ["+ SA2->A2_COD +"] no MIX ["+ ZLE->ZLE_COD +"] na Linha ["+ ZL3->ZL3_COD +"].","GLTXFUN012")
	Else
		_nRet := _nVlr * ( SA2->A2_L_TXFRT / 100 )
	EndIf
EndIf

Return(_nRet)

/*
===============================================================================================================================
Programa----------: PgFreLT
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 16/10/2010
Descrição---------: Funcao usada para retornar o valor a ser pago ao Fretista de Latao de acordo com o valor que foi descontado
------------------: do produtor para pagamento deste fretista. (ZL8)
Parametros--------: _cCodEve - Código do Evento
Retorno-----------: _nValRet - Valor a ser pago
===============================================================================================================================
*/
User Function PGFRELT(_cCodEve As Character)

Local _aArea	:= FWGetArea() As Array
Local _cAlias	:= GetNextAlias() As Character
Local _nValRet	:= 0 As Numeric

//====================================================================================================
// Somente gera valor a pagar para frete de latao se o Fretista For responsável pela linha
//====================================================================================================
If SA2->A2_COD == ZL3->ZL3_FRETIS
	BeginSql alias _cAlias
		SELECT NVL(SUM(ZLF_TOTAL), 0) TOTAL
		  FROM %Table:ZLF%
		 WHERE D_E_L_E_T_ = ' '
		   AND ZLF_FILIAL = %xFilial:ZLF%
		   AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
		   AND ZLF_EVENTO = %exp:_cCodEve%
		   AND ZLF_SETOR = %exp:ZL2->ZL2_COD%
		   AND ZLF_LINROT = %exp:ZL3->ZL3_COD%
	EndSql

	_nValRet := (_cAlias)->TOTAL
	(_cAlias)->( DBCloseArea() )
	
	If _nValRet == 0
		FWAlertWarning("Não foi encontrado nenhum valor de desconto para os produtores na Linha: "+ ZL3->ZL3_COD +"! Para gerar o valor do Fretista deve ser processado "+;
				"o evento: "+ _cCodEve +" que gera os descontos aos produtores referente ao frete de latão.","GLTXFUN014")
	EndIf
	
EndIf

FWRestArea(_aArea)

Return(_nValRet)

/*
===============================================================================================================================
Programa----------: CalImpoRPA
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 16/10/2010
Descrição---------: Funcao utilizada para realizar o calculo dos impostos de INSS, IRRF e SEST/SENAT, sobre um autonomo
Parametros--------: _cCodAuton = codigo do autonomo
					_nValor = Valor a ser considerado para calculo
					_cTipoForn = Tipo do Fornedor (F - Fretista, O - Outros)
Retorno-----------: _aImpostos , {	_aResAux[03]	,; //_nVlrIrrf
							_aResAux[02]	,; //_nVlrInss
							_aResAux[01]	}) //_nVlrSest
===============================================================================================================================
*/
User Function CalImpoRPA(_cCodAuton As Character,_nValor As Numeric,_cTipoForn As Character)

Local _nbaseSest	:= 0 As Numeric
Local _nVlrSest		:= 0 As Numeric
Local _aImpostos	:= {} As Array
Local _aResAux		:= {} As Array
Local _aDadImp		:= {	_cCodAuton		,; //01 -- Código do Autônomo
							_nValor			,; //02 -- Valor Bruto
							'001'			,; //03 -- Condição de Pagamento
							'F'				,; //04 -- Tipo de Fornecedor
							1				 } As Array//05 -- Identificador de chamada

//Caso o tipo do Fornecedor seja Fretista calcula SEST/SENAT
If _cTipoForn == 'F'
	_nbaseSest	:=	_nValor 	* SuperGetMV("IT_BSSEST",.F.,20) / 100
	_nVlrSest 	:=	_nBaseSest 	* SuperGetMV("IT_VLRSEST",.F.,2.5) / 100 
EndIf
//Chama a rotina de cálculo de impostos para RPA Avulso
LjMsgRun( 'Verificando cálculo dos impostos...' , 'Aguarde!' , {|| CursorWait() , _aResAux := U_ITCALIMP( _aDadImp ) , CursorArrow() } )

aAdd( _aImpostos , {	_aResAux[03]	,; //_nVlrIrrf
						_aResAux[02]	,; //_nVlrInss
						_aResAux[01]	}) //_nVlrSest
	
Return _aImpostos 
                                                                                                                               
/*
===============================================================================================================================
Programa----------: GetFaixa
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/01/2012
Descrição---------: Funcao usada para verificar na tabela de faixas o valor de uma determina faixa (ZL8)
Parametros--------: _cFilial - Codigo da filial
------------------: _cSetor  - Codigo do setor
------------------: _cCod    - Codigo da faixa(Ex:000010 - Volume)
------------------: _cFaixa  - Valor de enquadramento da faixa
Retorno-----------: _nVlrFxa - Valor da Faixa
===============================================================================================================================
*/
User Function GetFaixa(_cFilial As Character,_cSetor As Character,_cCod As Character,_nFaixa As Numeric)

Local _aArea	:= FWGetArea() As Array
Local _cAlias	:= GetNextAlias() As Character
Local _nVlrFxa	:= 0 As Numeric

BeginSql alias _cAlias
	SELECT ZLA_VALOR
	  FROM %Table:ZLA%
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLA_FILIAL = %exp:_cFilial%
	   AND ZLA_SETOR = %exp:_cSetor%
	   AND ZLA_COD = %exp:_cCod%
	   AND ZLA_FXINI <= %exp:_nFaixa%
	   AND ZLA_FXFIM >= %exp:_nFaixa%
EndSql

If (_cAlias)->( !Eof() )
	_nVlrFxa := (_cAlias)->ZLA_VALOR
EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return(_nVlrFxa)

/*
===============================================================================================================================
Programa----------: MedLeite
Autor-------------: Jeonave
Data da Criacao---: 11/09/2008
Descrição---------: Funcao usada para retonar o volume médio do produtor dentro do mix de fechamento
Parametros--------: _cCodFxa - Código da Faixa
Retorno-----------: _nVolMed - Valor médio de volume do produtor
===============================================================================================================================
*/
User Function MedLeite( _cCodFxa As Character,_nVolLiq As Numeric)

Local _aArea	:= FWGetArea() As Array
Local _cAlias	:= GetNextAlias() As Character
Local _cMaxSeq  := SuperGetMV("LT_MAXFAIX",.F.,"0010") As Character//Armazenaa sequencia da  faixa  que um determinado produtor que seja dono do tanque podera alcancar.
Local _nVolMed	:= 0 As Numeric
Local _nNumDia	:= Val(SubStr(DToS(ZLE->ZLE_DTFIM),7,2)) As Numeric

_nVolMed := _nVolLiq / _nNumDia

//====================================================================================================
// Verifica  o produtor corrente eh o dono do tanque, pois para evitar que o dono do tanque coloque o
// leite dos seus usuarios em seu nome será estipulado um valor maximo a ser atingido
//====================================================================================================
If SA2->A2_L_CLASS == 'C'
	BeginSql alias _cAlias
	  SELECT ZLA_FXINI, ZLA_FXFIM
		FROM %Table:ZLA% ZLA
	  WHERE ZLA.D_E_L_E_T_ = ' '
	  AND ZLA_FILIAL = %xFilial:ZLA%
	  AND ZLA.ZLA_COD = %exp:_cCodFxa%
	  AND ZLA.ZLA_SEQ = %exp:_cMaxSeq%
	EndSql

	If (_cAlias)->( !Eof() )
		If _nVolMed > (_cAlias)->ZLA_FXFIM
			_nVolMed := (_cAlias)->ZLA_FXINI
		EndIf
	EndIf
	
	(_cAlias)->( DBCloseArea() )

EndIf

FWRestArea(_aArea)

Return(_nVolMed)

/*
===============================================================================================================================
Programa----------: MesAnter
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 18/04/2012
Descrição---------: Funcao usada para retonar o valor do Evento com base no MIX anterior ao MIX que esta efetuando o lançamento
					 (ZL8). Usado no ZL8_FORMUL
Parametros--------: _nOpcao
Retorno-----------: _nVlrEve
===============================================================================================================================
*/
User Function MesAnter(_nOpcao As Numeric)

Local _aArea    := FWGetArea() As Array
Local _cMixAnt	:= '' As Character
Local _cCampos	:= '' As Character
Local _cAlias	:= GetNextAlias() As Character       
Local _nVolume	:= 0 As Numeric
Local _nVlrEve	:= 0 As Numeric

Default _nOpcao	:= 0

// Retorna o código do MIX anterior ao atual que possua fechamento do Evento realizado
BeginSql alias _cAlias
	SELECT NVL(MAX(ZLE.ZLE_COD),'000000') MIX
	  FROM %Table:ZLE% ZLE, %Table:ZLF% ZLF
	 WHERE ZLE.D_E_L_E_T_ = ' '
	   AND ZLF.D_E_L_E_T_ = ' '
	   AND ZLF.ZLF_CODZLE = ZLE.ZLE_COD
	   AND ZLE.ZLE_COD < %exp:ZLE->ZLE_COD%
	   AND ZLF.ZLF_EVENTO = %exp:ZL8->ZL8_COD%
	   AND ZLF.ZLF_ACERTO = 'S'
EndSql

_cMixAnt := (_cAlias)->MIX
(_cAlias)->( DBCloseArea() )

// Seleciona o valor gerado no Evento do MIX anterior ao corrente
_cCampos := "% "+IIf( _nOpcao == 1 , " AVG(ZLF_VLRLTR) AS VLREVENTO " , " AVG(ZLF_TOTAL) AS VLREVENTO " )+" %"
BeginSql alias _cAlias
	SELECT %exp:_cCampos%
	  FROM %Table:ZLF%
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLF_FILIAL = %xFilial:ZLF%
	   AND ZLF_EVENTO = %exp:ZL8->ZL8_COD%
	   AND ZLF_SETOR = %exp:ZL2->ZL2_COD%
	   AND ZLF_A2COD = %exp:SA2->A2_COD%
	   AND ZLF_A2LOJA = %exp:SA2->A2_LOJA%
	   AND ZLF_CODZLE = %exp:_cMixAnt%
EndSql

If (_cAlias)->( !Eof() )
	If _nOpcao == 1
		_nVolume := U_VolLeite( cFilAnt , ZLE->ZLE_DTINI , ZLE->ZLE_DTFIM , ZL2->ZL2_COD , ZL3->ZL3_COD , SA2->A2_COD , SA2->A2_LOJA , '' )
		_nVlrEve := (_cAlias)->VLREVENTO * _nVolume
	Else
		_nVlrEve := (_cAlias)->VLREVENTO
	EndIf
EndIf

(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return(_nVlrEve)

/*
===============================================================================================================================
Programa----------: GL_MOVLT
Autor-------------: Alexandre Villar
Data da Criacao---: 11/07/2014
Descrição---------: Verifica a Linha do Fornecedor quanto à entrega de leite e movimentações (ZL8). Usado no ZL8_CONDIC
Parametros--------: Nenhum (ZLE,ZL3,SA2 devem estar posicionadas) 
Retorno-----------: lret - .T. se a linha teve movimentações
===============================================================================================================================
*/
User Function GL_MOVLT

Local _aArea	:= FWGetArea() As Array
Local _lRet		:= .T. As Logical
Local _nVolLt	:= 0 As Numeric

_nVolLt := U_VolLeite( xFilial("ZL8") , ZLE->ZLE_DTINI , ZLE->ZLE_DTFIM , ZL3->ZL3_SETOR , ZL3->ZL3_COD , SA2->A2_COD , SA2->A2_LOJA , , 1 )

If _nVolLt > 0
	_lRet := .T.
Else
	_lRet := .F.
EndIf

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: GLTF3SB1
Autor-------------: Alexandre Villar
Data da Criacao---: 29/01/2015
Descrição---------: Consulta genérica para F3 do Produto na Recepção de Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GLTF3SB1

Local _lRet		:= .F. As Logical
Local _nRetorno	:= 0 As Numeric
Local _cQuery	:= "" As Character

_cQuery := " SELECT DISTINCT "
_cQuery += " 	SB1.B1_COD, SB1.B1_DESC, SB1.R_E_C_N_O_ "
_cQuery += " FROM  "+      RetSQLName('SB1') +" SB1 "
_cQuery += " INNER JOIN "+ RetSQLName('ZA7') +" ZA7 "
_cQuery += " ON "
_cQuery += "     ZA7.ZA7_CODPRD = SB1.B1_COD "
_cQuery += " WHERE "+ RetSQLCond("SB1,ZA7")

If Tk510F3Qry( _cQuery , "B1_COD , B1_DESC" , "R_E_C_N_O_" , @_nRetorno ,, { "B1_COD" , "B1_DESC" } , "SB1" )

	DBSelectArea("SB1")
	SB1->( DBGoTo( _nRetorno ) )
	_lRet := .T.
	
EndIf

Return(_lRet)

/*
===============================================================================================================================
Programa----------: GLTVANO
Autor-------------: Alexandre Villar
Data da Criacao---: 08/04/2015
Descrição---------: Rotina para validar o Volume de Leite movimentado no ano atual do Produtor posicionado (SA2)
Parametros--------: _nvolim - volume do leite movimentado  (SA2 deve estar posicionado)
					_dDtIni - Data inicial do MIX  (ZLE deve estar posicionado)
					_dDtFim - Data final do MIX  (ZLE deve estar posicionado)
Retorno-----------: lret - .T. se o volume é maior que o volume registrado na ZLD para o ano corrente
===============================================================================================================================
*/
User Function GLTVAno(_nVolLim As Numeric,_dDtIni As Date,_dDtFim As Date)

Local _lRet		:= .F. As Logical
Local _cAlias	:= GetNextAlias() As Character
_dDtIni	:= SToD( cValToChar( Year( _dDtIni ) ) + '0101' )

BeginSql alias _cAlias
	SELECT SUM(ZLD_QTDBOM) VOLUME
	  FROM %Table:ZLD% ZLD, %Table:SA2% SA2
	 WHERE ZLD.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
	   AND SA2.A2_FILIAL = %xFilial:SA2%
	   AND SA2.A2_COD = ZLD.ZLD_RETIRO
	   AND SA2.A2_LOJA = ZLD.ZLD_RETILJ
	   AND SA2.A2_CGC = %exp:SA2->A2_CGC%
	   AND SA2.A2_INSCR = %exp:SA2->A2_INSCR%
	   AND ZLD.ZLD_DTCOLE BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
EndSql  

_lRet := ( (_cAlias)->VOLUME < _nVolLim )
(_cAlias)->( DBCloseArea() )

Return(_lRet)

/*
===============================================================================================================================
Programa----------: GLTCIPL
Autor-------------: Alexandre Villar
Data da Criacao---: 08/04/2015
Descrição---------: Rotina para calcular o evento de Incentivo à produção leiteira
Parametros--------: _nValPer  - valor de referência
Retorno-----------: _nvalor - valor total, valor de referência vezes total do volume na zlf
===============================================================================================================================
*/
User Function GLTCIPL(_nValPer As Numeric)

Local _nValor	:= 0 As Numeric
Local _nValRef	:= _nValPer / 100 As Numeric
Local _cAlias	:= GetNextAlias() As Character

If Upper(SubStr(SA2->A2_COD,1,1)) == 'P'
	BeginSql alias _cAlias
		SELECT NVL(SUM(ZLF.ZLF_TOTAL),0) CREDITO
		  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
		 WHERE ZLF.D_E_L_E_T_ = ' '
		   AND ZL8.D_E_L_E_T_ = ' '
		   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
		   AND ZL8.ZL8_FILIAL = %xFilial:ZL8%
		   AND ZLF.ZLF_CODZLE = %exp:ZLE->ZLE_COD%
		   AND ZLF.ZLF_A2COD = %exp:SA2->A2_COD%
		   AND ZLF.ZLF_A2LOJA = %exp:SA2->A2_LOJA%
		   AND ZLF.ZLF_SETOR = %exp:ZL2->ZL2_COD%
		   AND ZLF.ZLF_LINROT = %exp:ZL3->ZL3_COD%
		   AND ZLF.ZLF_A2COD LIKE 'P%'
		   AND ZLF.ZLF_ACERTO NOT IN ('B', 'S') /*Nao seleciona bloqueados e se já tiveram acerto*/
		   AND ZLF.ZLF_ORIGEM = 'M' /*ZLF gerada pelo Mix*/
		   AND ZLF.ZLF_TP_MIX = 'L' /*Tipo do Mix igual a Leite*/
		   AND ZLF.ZLF_DEBCRE = 'C' /*Somente eventos de Credito*/
		   AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
		   AND ZL8.ZL8_SB1COD <> ' ' /*Somente eventos com codigo de produto*/
		   AND ZL8.ZL8_IMPNF = 'S' /*Somente eventos que são impressos na Nota*/
		   AND ZL8.ZL8_DEBCRE = 'C' /*Somente eventos de Credito*/
		 ORDER BY ZLF_SETOR, ZLF_LINROT
	EndSql

	_nValor := (_cAlias)->CREDITO * _nValRef
	(_cAlias)->( DBCloseArea() )

EndIf

Return(_nValor)

/*
===============================================================================================================================
Programa----------: GLTF3PLA
Autor-------------: Alexandre Villar
Data da Criacao---: 2014
Descrição---------: Rotina consulta via F3 pelas placas de veículos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GLTF3PLA

Local _cRet		:= '' As Character
Local _cAlias	:= GetNextAlias() As Character
Local _cTitAux	:= 'Placas de Veículos - Entregas de Leite de Terceiros' As Character
Local _aDados	:= {} As Array
Local _nI		:= 0 As Numeric

BeginSql alias _cAlias
	SELECT DISTINCT ZLX_PLACA, ZLX_TRANSP, ZLX_LJTRAN
	  FROM %Table:ZLX%
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLX_FILIAL = %xFilial:ZLX%
	 ORDER BY ZLX_PLACA
EndSql

While (_cAlias)->( !Eof() )
	aAdd( _aDados , {	.F.																								,;
						(_cAlias)->ZLX_PLACA																			,;
						(_cAlias)->ZLX_TRANSP +'/'+ (_cAlias)->ZLX_LJTRAN												,;
						Posicione( "SA2" , 1 , xFilial("SA2") + (_cAlias)->( ZLX_TRANSP + ZLX_LJTRAN ) , "A2_NOME" )	})
	
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If U_ITListBox( _cTitAux , { '__' , 'Placa' , 'Cód. Transp.' , 'Transportador' } , @_aDados , .F. , 2 , 'Selecione as placas desejadas: ' )
	For _nI := 1 To Len( _aDados )
		If _aDados[_nI][01]
			_cRet += _aDados[_nI][02] +';'
		EndIf
	Next _nI
	&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )
EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: GLTF3CAP
Autor-------------: Alexandre Villar
Data da Criacao---: 20/07/2015
Descrição---------: Rotina para utilização da consulta padrão das capacidades de cargas de veículos da recep. de leite de terc.
Uso---------------: Italac - Gestão do Leite
Parametros--------: Nenhum
Retorno-----------: Sempre .T.
===============================================================================================================================
*/
User Function GLTF3CAP

Local _cRet		:= '' As Character
Local _cTitAux	:= 'Capacidades de Carga de Veículos - Leite de Terceiros' As Character
Local _aDados	:= {} As Array
Local _aSX5		:= FWGetSX5( "CP" ) As Array
Local _nI		:= 0 As Numeric

For _nI := 1 To Len(_aSX5)
	aAdd( _aDados , { .F. , _aSX5[_nI][4]} )
Next _nI

If U_ITListBox( _cTitAux , { 'X' , 'Capacidade' } , @_aDados , .F. , 2 , 'Selecione as capacidades desejadas: ' )
	For _nI := 1 To Len( _aDados )
		If _aDados[_nI][01]
			_cRet += AllTrim( _aDados[_nI][02] ) +';'
		EndIf
	Next _nI
	&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )
EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: GLTF3TL3
Autor-------------: Alexandre Villar
Data da Criacao---: 11/09/2008
Descrição---------: Rotina para utilização da consulta padrão dos tipos de produtos da recepção de leite de terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GLTF3TL3

Local _cRet		:= '' As Character
Local _cTitAux	:= 'Tipos de produtos - Leite de Terceiros' As Character
Local _aDados	:= {} As Array
Local _aSX5		:= FWGetSX5( "Z7" ) As Array
Local _nI		:= 0 As Numeric

For _nI := 1 To Len(_aSX5)
	aAdd( _aDados , { .F. , _aSX5[_nI][3], _aSX5[_nI][4]} )
Next _nI

If U_ITListBox( _cTitAux , { 'X' , 'Código' , 'Descrição' } , @_aDados , .F. , 2 , 'Selecione as capacidades desejadas: ' )
	For _nI := 1 To Len( _aDados )
		If _aDados[_nI][01]
			_cRet += AllTrim( _aDados[_nI][02] ) +';'
		EndIf
	Next _nI
	&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )
EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: getNwTicket
Autor-------------: Abrahao
Data da Criacao---: 24/12/2008
Descrição---------: Funcao usada para pegar numero maximo do Ticket
arametros--------: lvalid - retornar sempre .T. para Private cticket não vazia
Retorno-----------: .T. par ticket válido
===============================================================================================================================
*/
User Function getNwTicket(lvalid As Logical)

Local cRet	:= "" As Character
Local lRet	:= .F. As Logical
Local aArea	:= FWGetArea() As Array

If lvalid
	If !Empty( cTicket )
		Return( .T. )
	EndIf
EndIf

DBSelectArea("ZL2")
ZL2->( DBSetOrder(1) )
If ZL2->( DBSeek( xFilial("ZL2") + cSetor ) ) .And. xFilial("ZL2") + cSetor == ZL2->ZL2_FILIAL + ZL2->ZL2_COD 
	cRet := ZL2->ZL2_TICKET
	
	If Empty( AllTrim(cRet) )
		cRet := StrZero( 1 , Len(ZL2->ZL2_TICKET) )
	EndIf
	
	cRet:= StrZero(Val(cRet),Len(ZL2->ZL2_TICKET))

	ZL2->( RecLock( "ZL2" , .F. ) )
	ZL2->ZL2_TICKET := Soma1(cRet)
	ZL2->( MSUnLock() )
	
	cTicket	:= StrZero(Val(cRet),Len(ZLW->ZLW_TICKET))//cRet
	lRet	:= .T.
Else
	FWAlertWarning("Setor nao encontrado! Selecione um Setor válido!","GLTXFUN015")
	If Empty( cSetor )
	     lRet := .T.
	EndIf
EndIf

ZL2->(DBCloseArea())

FWRestArea(aArea)

Return(lRet)

/*
===============================================================================================================================
Programa----------: getNumRec
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para pegar numero maximo de recebimento
Parametros--------: Nenhum
Retorno-----------: próximo valor para ZLD_CODREC
===============================================================================================================================
*/
User Function getNumRec

Local _cRet		:= "" As Character
Local _aArea	:= FWGetArea() As Array
Local _cAlias   := GetNextAlias() As Character

BeginSql alias _cAlias
	SELECT NVL(MAX(ZLD_CODREC),'000000') ULTIMO
	  FROM %Table:ZLD%
	 WHERE ZLD_FILIAL = %xFilial:ZLD%
	   AND D_E_L_E_T_ = ' '
EndSql
_cRet := Soma1((_cAlias)->ULTIMO)
(_cAlias)->( DBCloseArea() )

While !MayIUseCode( "ZLD_CODREC"+ xFilial("ZLD") + _cRet )  // verifica se esta na memoria, sendo usado
   _cRet := Soma1(_cRet)							           // busca o proximo numero disponivel
EndDo 

FWRestArea(_aArea)

Return(_cRet)

/*
===============================================================================================================================
Programa----------: getNumRww
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para pegar numero maximo de recebimento
Parametros--------: Nenhum
Retorno-----------: CRET - próximo valor para ZLW_CODREC
===============================================================================================================================
*/
User Function getNumRww

Local _cRet		:= "" As Character
Local _aArea	:= FWGetArea() As Array
Local _cAlias   := GetNextAlias() As Character

BeginSql alias _cAlias
	SELECT NVL(MAX(ZLW_CODREC),'000000') ULTIMO
	  FROM %Table:ZLW%
	 WHERE ZLW_FILIAL = %xFilial:ZLW%
	   AND D_E_L_E_T_ = ' '
EndSql

_cRet := Soma1((_cAlias)->ULTIMO)
(_cAlias)->( DBCloseArea() )

While !MayIUseCode( "ZLW_CODREC"+ xFilial("ZLW") + _cRet )  // verifica se esta na memoria, sendo usado
   _cRet := Soma1(_cRet)						           // busca o proximo numero disponivel
EndDo 

FWRestArea(_aArea)

Return(_cRet)

/*
===============================================================================================================================
Programa--------: GLTEnXml
Autor-----------: Alexandre Villar
Data da Criacao-: 03/06/2015
Descrição-------: Rotina para envio de XML para o serviço de WS
Parametros------: _cWS		- Endereço Web do serviço de WebService
----------------: _cXmlEnv	- Conteúdo do arquivo XML a enviar
----------------: _aHdrOut	- Array com as configurações adicionais do serviço que são incluídas no XML de envio
----------------: _cErro	- Variável que receberá as mensagens de erro
----------------: _cMétodo	- Utilizada para identificar o método que será instanciado no serviço e tratar o retorno
----------------: _cXmlRet	- Dados com as informações de retorno do serviço
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function GLTSQENV(_cWS As Character,_cXmlEnv As Character, _aHdrOut As Array,_cErro As Character,_cMetodo As Character,_cXmlRet As Character)

Local _nStart 		:= 0 As Numeric
Local _nRetry 		:= 0 As Numeric
Local _cXmlHdr	 	:= '' As Character
Local _nPosAux		:= 0 As Numeric
Local _nTimOut	 	:= 120 As Numeric
_aHdrOut		:= {}
_cXmlRet	:= ''
_cErro		:= ''

//====================================================================================================
// Tenta por 2 minutos ou 3 vezes antes de abortar
//====================================================================================================
_nStart := Seconds()
_nRetry := 0

While _nRetry < 3
	_cXmlRet := AllTrim( HttpPost( _cWS , '' , _cXmlEnv , _nTimOut , _aHdrOut , @_cXmlHdr ) )
	_cXmlRet := NoAcento( _cXmlRet )
	If _cXmlRet <> Nil
		_nRetry := 4
		Exit
	Else
		_nRetry++
		If ( Seconds() - _nStart ) >= _nTimOut
			_nRetry := 4
			Exit
		EndIf
	EndIf
EndDo

If !Empty( _cXmlRet )

	// Tratamento do Xml de Retorno
	If "<FAULTSTRING>" $ Upper( _cXmlRet )
		_cXmlRet	:= Upper( _cXmlRet )
		_nPosAux 	:= At( '<FAULTSTRING>' , _cXmlRet )
		_cXmlRet	:= SubStr( _cXmlRet , _nPosAux + Len('<FAULTSTRING>') )
		_nPosAux 	:= At( '</FAULTSTRING>' , _cXmlRet )
		_cXmlRet	:= SubStr(_cXmlRet , 1 , _nPosAux - 1 )
		_cErro		:= _cXmlRet
	ElseIf	Upper("Service Temporarily Unavailable") $ Upper( _cXmlRet ) .Or. Upper("No service was found") $ Upper( _cXmlRet ) 
		_cErro := _cXmlRet
	Else
		Do	Case
			Case Upper( _cMetodo ) == 'ENV_PRODUTOR'
				_cVarAx1	:= '<oid>'
				_cVarAx2	:= '</oid>'
				_nPosAux 	:= At(_cVarAx1,_cXmlRet)
				_cXmlRet	:= SubStr( _cXmlRet , _nPosAux + Len(_cVarAx1) )
				_nPosAux 	:= At(_cVarAx2,_cXmlRet)
				_cXmlRet	:= 'Gravação realizada com sucesso. [Id.'+ SubStr(_cXmlRet , 1 , _nPosAux - 1 ) +']'
			Case Upper( _cMetodo ) == 'ENV_USUARIO'
				_cVarAx1	:= '<oid>'
				_cVarAx2	:= '</oid>'
				_nPosAux 	:= At(_cVarAx1,_cXmlRet)
				_cXmlRet	:= SubStr( _cXmlRet , _nPosAux + Len(_cVarAx1) )
				_nPosAux 	:= At(_cVarAx2,_cXmlRet)
				_cXmlRet	:= 'Gravação realizada com sucesso. [Id.'+ SubStr(_cXmlRet , 1 , _nPosAux - 1 ) +']'
			Case Upper( _cMetodo ) == 'GET_ATENDIM'
				_cVarAx1	:= '<soap:Body>'
				_cVarAx2	:= '</soap:Envelope>'
				_nPosAux 	:= At( _cVarAx1 , _cXmlRet )
				_cXmlRet	:= SubStr( _cXmlRet , _nPosAux )
				_nPosAux 	:= At(_cVarAx2,_cXmlRet)
				_cXmlRet	:= SubStr(_cXmlRet , 1 , _nPosAux - 1 )
			Case Upper( _cMetodo ) == 'GET_DADOSAT'
				_cVarAx1	:= '<soap:Body>'
				_cVarAx2	:= '</soap:Envelope>'
				_nPosAux 	:= At( _cVarAx1 , _cXmlRet )
				_cXmlRet	:= SubStr( _cXmlRet , _nPosAux )
				_nPosAux 	:= At(_cVarAx2,_cXmlRet)
				_cXmlRet	:= SubStr(_cXmlRet , 1 , _nPosAux - 1 )
		EndCase
    EndIf
Else
	_cErro := 'A Chamada do endereco: '+_cWS+' retornou em branco. Se o problema persistir informe a área de TI/ERP.'
EndIf

Return

/*
===============================================================================================================================
Programa--------: GLTSQXML
Autor-----------: Alexandre Villar
Data da Criacao-: 03/06/2015
Descrição-------: Rotina para montagem básica do XML de acordo com o ponto e o método solicitado
Parametros------: _nOpc		- Opção do ponto do XML
----------------: _cMetodo	- Identificação do método que está sendo utilizado
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function GLTSQXML(_nOpc As Numeric,_cMetodo As Character)

Local _cXmlRet	:= "" As Character
Local _cLogin	:= SuperGetMV("LT_SMQLOGN",.F.,"protheus") As Character
Local _cPasswd	:= SuperGetMV("LT_SMQPASS",.F.,"italac#123") As Character

If _nOpc == 1
	_cXmlRet := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v9="http://v9.webservice.server.smartquestion.logann.com.br/">'+ CRLF
	_cXmlRet += '	<soapenv:Header/>' +CRLF
	_cXmlRet += '	<soapenv:Body>' +CRLF
	Do Case
		Case Upper( AllTrim( _cMetodo ) ) == 'ENV_PRODUTOR'
			_cXmlRet += '		<v9:criarOuAtualizarPontoAtendimentos>' +CRLF
		Case Upper( AllTrim( _cMetodo ) ) == 'ENV_USUARIO'
			_cXmlRet += '		<v9:criarOuAtualizarUsuarios>' +CRLF
		Case Upper( AllTrim( _cMetodo ) ) == 'GET_ATENDIM'
			_cXmlRet += '		<v9:getExecucaoDiaTrabalhoCriadoOuModificado>' +CRLF
		Case Upper( AllTrim( _cMetodo ) ) == 'GET_DADOSAT'
			_cXmlRet += '		<v9:getAtendimentosPeloNumero>' +CRLF
	EndCase
	
	_cXmlRet += '			<login>'+ _cLogin  +'</login>' +CRLF
	_cXmlRet += '			<senha>'+ _cPasswd +'</senha>' +CRLF
ElseIf _nOpc == 2
	Do Case
		Case Upper( AllTrim( _cMetodo ) ) == 'ENV_PRODUTOR'
			_cXmlRet += '		</v9:criarOuAtualizarPontoAtendimentos>' +CRLF
		Case Upper( AllTrim( _cMetodo ) ) == 'ENV_USUARIO'
			_cXmlRet += '		</v9:criarOuAtualizarUsuarios>' +CRLF
		Case Upper( AllTrim( _cMetodo ) ) == 'GET_ATENDIM'
			_cXmlRet += '		</v9:getExecucaoDiaTrabalhoCriadoOuModificado>' +CRLF
		Case Upper( AllTrim( _cMetodo ) ) == 'GET_DADOSAT'
			_cXmlRet += '		</v9:getAtendimentosPeloNumero>' +CRLF
	EndCase
	
	_cXmlRet += '	</soapenv:Body>' +CRLF
	_cXmlRet += '</soapenv:Envelope>' +CRLF
EndIf

Return(_cXmlRet)

/*
===============================================================================================================================
Programa----------: CalFrete
Autor-------------: Alex Wallauer
Data da Criacao---: 24/05/2018
Descrição---------: Funcao usada para retornar o valor do frete do veiculo do Fretista para o MIX/Setor/Linha posicionados (ZL8)
Parametros--------: _cTipo: "KM", "LITRO", "KM_OLD", "LITRO_OLD"
Retorno-----------: _nValFret: valor do frete do veiculo do Fretista
===============================================================================================================================
*/
User Function CalFrete(_cTipo As Character,_nKmRet As Numeric,_cVeiculo As Character,_nVolFRT As Numeric)

Local _aArea		:= FWGetArea() As Array
Local _nValFret		:= 0 As Numeric
Local _nX			:= 0 As Numeric
Local _aViagens		:= {} As Array
Local _cAlias		:= GetNextAlias() As Character
Local _lMix			:= FWIsInCallStack("U_AGLT020") .Or. FWIsInCallStack("U_AGLT020J") As Logical
Local _cUpdate		:= "" As Character
Local _cFiltro		:= "" As Character
Local _cFiltro2		:= "" As Character
Local _cFiltro3		:= "" As Character
Default _nKmRet		:=0 
Default _nVolFRT	:=0 

_cFiltro += " WHERE ZLD.D_E_L_E_T_ = ' ' "
_cFiltro +=" AND ZLD_FILIAL = '"+xFilial("ZLD")+"' "
_cFiltro +=" AND ZLD_SETOR = '"+ZL2->ZL2_COD+"' "
_cFiltro +=" AND ZLD_LINROT = '"+ZL3->ZL3_COD+"' "
_cFiltro +=" AND ZLD_DTCOLE BETWEEN '"+DToS(ZLE->ZLE_DTINI)+"' AND '"+DToS(ZLE->ZLE_DTFIM)+"' "
_cFiltro +=" AND ZLD_FRETIS = '"+SA2->A2_COD+"' "
_cFiltro +=" AND ZLD_LJFRET = '"+SA2->A2_LOJA+"' "
_cFiltro2+=" (SELECT NVL(SUM(ZLD_QTDBOM),0) VOLUME "
_cFiltro2+=" FROM "+RetSqlName("ZLD")+" A "
_cFiltro2+=" WHERE ZLD.D_E_L_E_T_ = ' ' "
_cFiltro2+=" AND ZLD.ZLD_FILIAL = A.ZLD_FILIAL "
_cFiltro2+=" AND ZLD.ZLD_SETOR = A.ZLD_SETOR "
_cFiltro2+=" AND ZLD.ZLD_LINROT = A.ZLD_LINROT "
_cFiltro2+=" AND ZLD.ZLD_DTCOLE = A.ZLD_DTCOLE "
_cFiltro2+=" AND ZLD.ZLD_FRETIS = A.ZLD_FRETIS "
_cFiltro2+=" AND ZLD.ZLD_LJFRET = A.ZLD_LJFRET "
_cFiltro2+=" AND ZLD.ZLD_TICKET = A.ZLD_TICKET ) "

If _cTipo == "KM_OLD"
	_nValFret := U_GETKM(xFilial("ZL8"),ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,SA2->A2_LOJA,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM)*ZL3->ZL3_VLRFRT
	_cUpdate:="UPDATE "+RetSqlName("ZLD")+" ZLD SET ZLD_VLRFRE = "+cValToChar(ZL3->ZL3_VLRFRT)+"*ZLD_KM, ZLD_VTABFR = "+cValToChar(ZL3->ZL3_VLRFRT) + _cFiltro
	If TCSqlExec(_cUpdate) < 0
		MsgStop("Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError()),"GLTXFUN010")
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "AGLT020"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "GLTXFUN010"/*cMsgId*/, "Filial: "+cFilant+"] - Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
ElseIf _cTipo == "LITRO_OLD"
	_nValFret := IIf(ZL3->ZL3_VLRFRT>0,U_VFRETE()*ZL3->ZL3_VLRFRT,0)
	_cUpdate:="UPDATE "+RetSqlName("ZLD")+" ZLD SET ZLD_VLRFRE = "+cValToChar(ZL3->ZL3_VLRFRT)+"*"+_cFiltro2+" , ZLD_VTABFR = "+cValToChar(ZL3->ZL3_VLRFRT)+ _cFiltro
	If TCSqlExec(_cUpdate) < 0
		MsgStop("Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError()),"GLTXFUN008")
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "AGLT020"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "GLTXFUN008"/*cMsgId*/, "Filial: "+cFilant+"] - Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
ElseIf _cTipo == "DIA"
	_nValFret := U_GETDIAFRT(xFilial("ZL8"),ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,SA2->A2_LOJA,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM)*ZL3->ZL3_VLRFRT
	_cUpdate:="UPDATE "+RetSqlName("ZLD")+" ZLD SET ZLD_VLRFRE = "
	_cUpdate+=cValToChar(_nValFret)+"/ (SELECT COUNT(1) FROM (SELECT ZLD_TICKET FROM "+RetSqlName("ZLD")+" ZLD "+ _cFiltro + " GROUP BY ZLD_TICKET)) "
	_cUpdate+=" , ZLD_VTABFR = "+cValToChar(_nValFret)+"/ (SELECT COUNT(1) FROM (SELECT ZLD_TICKET FROM "+RetSqlName("ZLD")+" ZLD " + _cFiltro + " GROUP BY ZLD_TICKET)) " + _cFiltro
	If TCSqlExec(_cUpdate) < 0
		MsgStop("Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError()),"GLTXFUN009")
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "AGLT020"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "GLTXFUN009"/*cMsgId*/, "Filial: "+cFilant+"] - Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
Else
	DBSelectArea("ZFF")
	ZFF->( DBSetOrder(1) )
	DBSelectArea("ZFG")
	ZFG->( DBSetOrder(1) )
	_cFiltro3 := "% "+IIf(_cTipo == "LITRO"," "," AND ZLD_KM > 0 ")+"%"

	If _nKmRet > 0
		BeginSql alias _cAlias
			SELECT ZL1_COD VEICULO, ZL1_TABFRE
			FROM %Table:ZL1% ZL1
			WHERE ZL1.D_E_L_E_T_ = ' '
			AND ZL1_FILIAL = %xFilial:ZL1%
			AND ZL1_COD = %exp:_cVeiculo%
		EndSql
	Else
		BeginSql alias _cAlias
			SELECT ZLD_VEICUL VEICULO, ZL1_TABFRE
			FROM %Table:ZLD% ZLD, %Table:ZL1% ZL1
			WHERE ZLD.D_E_L_E_T_ = ' '
			AND ZL1.D_E_L_E_T_ = ' '
			%exp:_cFiltro3%
			AND ZLD_FILIAL = %xFilial:ZLD%
			AND ZL1_FILIAL = %xFilial:ZL1%
			AND ZLD_SETOR = %exp:ZL2->ZL2_COD%
			AND ZLD_LINROT = %exp:ZL3->ZL3_COD%
			AND ZLD_VEICUL = ZL1_COD
			AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
			AND ZLD_FRETIS = %exp:SA2->A2_COD%
			AND ZLD_LJFRET = %exp:SA2->A2_LOJA%
			GROUP BY ZLD_VEICUL, ZL1_TABFRE
		EndSql
	EndIf
	While (_cAlias)->( !Eof() )
		_aViagens:={}
		If _cTipo == "LITRO"
			If _nVolFRT == 0
				_nVolFRT:=U_VFRETE((_cAlias)->VEICULO)
			EndIf
			
			If _nVolFRT > 0
				//ZL3 já esta posicionado
				If ZL3->ZL3_PRCLTR = "1"//"1=Sim;2=Não"
					If ZFF->(DBSeek(xFilial("ZFF")+(_cAlias)->ZL1_TABFRE))
						_nValFret+=(_nVolFRT*ZFF->ZFF_PRCLTR)
						_nMultiplicador:=ZFF->ZFF_PRCLTR//Variavel usada no programa RGLR023.PRW
						If _lMix
							_cUpdate:="UPDATE "+RetSqlName("ZLD")+" ZLD SET ZLD_VLRFRE = "+cValToChar(ZFF->ZFF_PRCLTR)+"*"+_cFiltro2+" , ZLD_VTABFR = "+cValToChar(ZFF->ZFF_PRCLTR) + _cFiltro
							_cUpdate+=" AND ZLD_VEICUL = '"+(_cAlias)->VEICULO+"'"
							If TCSqlExec(_cUpdate) < 0
								MsgStop("Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError()),"GLTXFUN004")
								FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "AGLT020"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "GLTXFUN004"/*cMsgId*/, "Filial: "+cFilant+"] - Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf	
		ElseIf _cTipo == "KM"	
			//"1=Tabela de Faixas;2=Exceção;3=Não"
			If ZFF->(DBSeek(xFilial("ZFF")+(_cAlias)->ZL1_TABFRE))
				//ZL3 já esta posicionado
				If ZL3->ZL3_PRCEXE == "1"//1=Tabela de Faixas
					If _nKmRet == 0
					_aViagens:=U_GETKM(xFilial("ZL8"),ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,SA2->A2_LOJA,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,(_cAlias)->VEICULO,.T.)//POR VIAGEM
					Else
					aAdd(_aViagens,{"",_nKmRet})
					EndIf
					
					For _nX := 1 To Len(_aViagens)
						If ZFG->( DBSeek( ZFF->ZFF_FILIAL + ZFF->ZFF_CODIGO ) )
							While ZFG->(!Eof()) .And. ZFG->ZFG_FILIAL + ZFG->ZFG_CODIGO == ZFF->ZFF_FILIAL + ZFF->ZFF_CODIGO
								If _aViagens[_nX,2] <=  ZFG->ZFG_KM_ATE
									_nValFret+=(_aViagens[_nX,2]*ZFG->ZFG_KMPREC)
									_nMultiplicador:=ZFG->ZFG_KMPREC//Variavel usada no programa RGLR023.PRW
									If _lMix
										_cUpdate:="UPDATE "+RetSqlName("ZLD")+" ZLD SET ZLD_VLRFRE = "+cValToChar((_aViagens[_nX,2]*ZFG->ZFG_KMPREC))+", ZLD_VTABFR = "+ cValToChar(ZFG->ZFG_KMPREC) + _cFiltro
										_cUpdate+=" AND ZLD_VEICUL = '"+(_cAlias)->VEICULO+"'"
										_cUpdate+=" AND ZLD_TICKET = '"+_aViagens[_nX,1]+"'"
										_cUpdate+=" AND ZLD_KM = " +cValtoChar(_aViagens[_nX,2]) //o Array aViagens agrupa por ticket e KM. Se não especificar qual o KM, em um ticket com 3 elementos ele vai repetir o último KM para os cálculos anteriores
										If TCSqlExec(_cUpdate) < 0
											MsgStop("Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError()),"GLTXFUN006")
											FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "AGLT020"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "GLTXFUN006"/*cMsgId*/, "Filial: "+cFilant+"] - Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
										EndIf
									EndIf
									Exit
								EndIf
								ZFG->(DBSkip())
							EndDo
						EndIf
					Next _nX
				ElseIf ZL3->ZL3_PRCEXE == "2"//2=Exceção
					If _nKmRet == 0
						_nKmRet:=U_GETKM(xFilial("ZL8"),ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,SA2->A2_LOJA,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,(_cAlias)->VEICULO,.F.)//TORLA
					EndIf
					If _nKmRet > 0
						_nValFret+=(_nKmRet*ZFF->ZFF_PRCEXE)
						_nMultiplicador:=ZFF->ZFF_PRCEXE//Variavel usada no programa RGLR023.PRW
						If _lMix
							_cUpdate:="UPDATE "+RetSqlName("ZLD")+" ZLD SET ZLD_VLRFRE = ZLD_KM*"+cValToChar(ZFF->ZFF_PRCEXE)+", ZLD_VTABFR = "+cValToChar(ZFF->ZFF_PRCEXE) + _cFiltro
							_cUpdate+=" AND ZLD_VEICUL = '"+(_cAlias)->VEICULO+"'"
							_cUpdate+=" AND ZLD_KM > 0 "
							If TCSqlExec(_cUpdate) < 0
								MsgStop("Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError()),"GLTXFUN007")
								FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "AGLT020"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "GLTXFUN007"/*cMsgId*/, "Filial: "+cFilant+"] - Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		_nKmRet := 0
		_nVolFRT := 0
		(_cAlias)->( DBSkip() )
	EndDo

	(_cAlias)->( DBCloseArea() )
	ZZF->( DBCloseArea() )
	ZZG->( DBCloseArea() )
EndIf

FWRestArea(_aArea)

Return(_nValFret)

/*
===============================================================================================================================
Programa----------: LisSetor
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/09/2018
Descrição---------: Valida se os setores recebidos via parâmetros ou em memória, podem ser acessdos pelo usuário corrente
Parametros--------: _lFil -> .T. -> indica se filtra setores da filial corrente
Retorno-----------: _cSetores -> lista com os setores que o usuário tem acesso
===============================================================================================================================
*/
User Function LisSetor(_lFil As Logical)

Local _cFiltro	:= "%" As Character
Local _cAlias 	:= GetNextAlias() As Character

Default _lFil	:= .F.

If _lFil
	_cFiltro += "AND ZL2.ZL2_FILIAL = '"+xFilial("ZL2")+"'"
EndIf
_cFiltro += "%"
If Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	BeginSql alias _cAlias
	SELECT LISTAGG(ZL2_COD, ';') WITHIN GROUP(ORDER BY ZL2_COD) COD
	  FROM %Table:ZL2% ZL2
	 WHERE ZL2.D_E_L_E_T_ = ' '
	   %exp:_cFiltro%
	   AND EXISTS
	 (SELECT 1 FROM %Table:ZLV% ZLV
	         WHERE ZLV.D_E_L_E_T_ = ' '
	           AND ZLV.ZLV_CODUSU = %Exp:RetCodUsr()%
	           AND ZLV.ZLV_SETOR = ZL2.ZL2_COD)
	EndSql
Else //Se usuário tem acesso à todos os setores, já busco todos
	BeginSql alias _cAlias
		SELECT LISTAGG(ZL2_COD, ';') WITHIN GROUP (ORDER BY ZL2_COD ) COD
		FROM %Table:ZL2% ZL2
		WHERE D_E_L_E_T_ = ' '
		%exp:_cFiltro%
	EndSql
EndIf
_cSetores := AllTrim((_cAlias)->COD)
(_cAlias)->(DBCloseArea())

Return (_cSetores)
/*
===============================================================================================================================
Programa----------: VSetor
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/09/2018
Descrição---------: Valida se os setores recebidos via parâmetros ou em memória, podem ser acessdos pelo usuário corrente
Parametros--------: _lFil -> .T. -> indica se valida se o setor pertence à filial corrente
					_aCodSet -> C -> código do setor a ser validado. Se não informar, carrega o que está na memória
Retorno-----------: .T. - Todos os setores recebidos podem ser acessados
					.F. - Retorna o primeiro setor da lista, que não está liberado para o usuário
===============================================================================================================================
*/
User Function VSetor(_lFil As Logical,_aCodSet As Variant)

Local _aArea	:= FWGetArea() As Array
Local _aSetUsr	:= "" As Array
Local _nI		:= 0 As Numeric
Local _oModel 	:= FWModelActive() As Object
Default _aCodSet:= ""
Default _lFil	:= .T.

//Monta lista dos setores informados e dos setores previamente liberados
_aCodSet := StrTokArr( IIf(Empty(_aCodSet),AllTrim(&( ReadVar() )),AllTrim(_aCodSet)), ';' )
//Informo .F. para não filtrar a filial. O tratamento da filial será feito abaixo
_aSetUsr := StrTokArr(U_LisSetor(.F.) , ';' )

For _nI := 1 To Len(_aCodSet)

	If !Empty( _aCodSet[_nI] )
		If aScan( _aSetUsr , _aCodSet[_nI] ) == 0
			//Verifico se a rotina que está fazendo a chamada é em MVC pois o padrão de mensagem é diferente
			If _oModel <> Nil .And. _oModel:IsActive()
				_oModel:SetErrorMessage('', '' , '' , '' , "GLTXFUN001", "Não foram informados setores válidos para o processamento. O setor ["+ _aCodSet[_nI] +"] não está liberado para utilização do usuário atual!", "Verifique os dados informados.")
			Else
				FWAlertWarning("Não foram informados setores válidos para o processamento. O setor ["+ _aCodSet[_nI] +"] não está liberado para utilização do usuário atual!","GLTXFUN001")
			EndIf
			Return (.F.)
		ElseIf _lFil .And. SubStr(_aCodSet[_nI],1,FWSizeFilial()) <> cFilAnt
			//Verifico se a rotina que está fazendo a chamada é em MVC pois o padrão de mensagem é diferente
			If _oModel <> Nil .And. _oModel:IsActive()
				_oModel:SetErrorMessage('', '' , '' , '' , "GLTXFUN002", "Não foram informados setores válidos para o processamento. O setor ["+ _aCodSet[_nI] +"] não pertence a essa Filial!", "Verifique os dados informados.")
			Else
				FWAlertWarning("Não foram informados setores válidos para o processamento. O setor ["+ _aCodSet[_nI] +"] não pertence a essa Filial!","GLTXFUN002")
			EndIf
			Return (.F.)
		EndIf
	EndIf

Next _nI

FWRestArea(_aArea)

Return (.T.)

/*
===============================================================================================================================
Programa----------: MedVol
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/10/2018
Descrição---------: Retorna volume de leite (ZL8)
Parametros--------: _cTpProd -> C -> Tipo do Produtor (Cooperativa, Próprio ou Atravessador) - A2_L_TIPPR
------------------: _dDtIni -> D -> Data Inicial para filtrar os movimentos
------------------: _dDtFim	-> D -> Data Final para filtrar os movimentos
------------------: _cCodFor -> C -> Código do produtor
------------------: _cLojFor -> C -> Loja do Produtor
					Usado na Integração com SmartQuestion
Retorno-----------: _nTotal	: Média de volume referente ao período informado
===============================================================================================================================
*/
User Function MedVol(_cTpProd As Character,_dDtIni As Date,_dDtFim As Date,_cCodFor As Character,_cLojFor As Character)

Local _cAlias	:= GetNextAlias() As Character
Local _cCampos	:= "%" As Character
Local _cFiltro	:= "%" As Character
Local _cTable	:= "%" As Character
Local _cAux		:= 'ZLD' As Character
Local _nTotal	:= 0 As Logical

If _cTpProd == 'C'
	_cAux := 'ZLW'
EndIf
_cCampos += " SUM("+ _cAux +"_QTDBOM) TBOM %"
_cTable += RetSqlName(_cAux) +" %"
_cFiltro += " AND "+ _cAux +"_DTCOLE BETWEEN '"+ DToS(_dDtIni) +"' AND '"+ DToS(_dDtFim) +"' "
_cFiltro += " AND "+ _cAux +"_RETIRO = '"+ _cCodFor +"' "
_cFiltro += " AND "+ _cAux +"_RETILJ = '"+ _cLojFor +"' %"

BeginSql alias _cAlias
	SELECT %exp:_cCampos% FROM %exp:_cTable%
	 WHERE D_E_L_E_T_ = ' ' 
	 %exp:_cFiltro%
EndSql

If (_cAlias)->( !Eof() )
	_nTotal  := Round((_cAlias)->TBOM/Abs(_dDtFim-_dDtIni),0)
EndIf

(_cAlias)->(DBCloseArea())

Return(_nTotal)

/*
===============================================================================================================================
Programa----------: RetImpGL
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 16/10/2018
Descrição---------: Retorna o valor do imposto a ser calculado no fechamento de Produtores de Leite.
Parametros--------: _lDefini -> L -> Indica se o imposto já está calculdo no documento de entrada (.T.) ou se é uma simulação (.F.)
					_cImp -> C -> Código do imposto a ser retornado (Ex: NF_VALINS, NF_VLSENAR, NF_FUNRURAL)	
					_nBase -> N -> Valor para ser utilizado como base do cálculo do imposto. Utilizado quando se quer calcular
									 em cima de um valor específico
Retorno-----------: _nValor -> N -> Valor do imposto
===============================================================================================================================
*/
User Function RetImpGL(_lDefini As Logical,_cImp As Character,_nBase As Numeric)

Local _cAlias		:= GetNextAlias() As Character
Local _cTES			:= '' As Character
Local _nValor		:= 0 As Numeric
Local _lNf1Item		:= If(SM0->M0_ESTENT == 'RO',.F.,.T.) As Logical
Local _cGroup		:= '' As Character
Local _cCampos		:= '' As Character
Default _nBase		:= 0

//Se é uma previsão do imposto, levanto informações básicas para simular os impostos
If !_lDefini
	//Inicia o processo de calculo da MatxFis, gerando um array do Cabecalho e Itens do Documento Fiscal
	MaFisIni(SA2->A2_COD/*cLoja*/,;	// 1-Cod. Cli/For
			SA2->A2_LOJA/*cLoja*/,; // 02-Lj do Cli/For
			"F"/*cCliFor*/,; 		// 03-C:Cliente , F:Fornecedor
			"N"/*cTipoNF*/,; 		// 04-Tp NF( "N","D","B","C","P","I" )
			/*cTpCliFor*/,; 		// 05-Tp do Cli/For
			{}/*aRelImp*/,;			// 06-Relacao de Impostos que suportados no arquivo
			/*cTpComp*/,;	  		// 07-Tipo de complemento
			/*lInsere*/,;	  		// 08-Permite Incluir Impostos no Rodape .T./.F.
			/*cAliasP*/,;	  		// 09-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
			"MT100"/*cRotina*/,;	  		// 10-Nome da rotina que esta utilizando a funcao
			/*cTipoDoc*/,;	  		// 11-Tipo de documento
			/*cEspecie*/,;	  		// 12-Especie do documento
			/*cCodProsp*/,;	  		// 13-Codigo e Loja do Prospect
			/*cGrpCliFor*/,;  		// 14-Grupo Cliente
			/*cRecolheISS*/,; 		// 15-Recolhe ISS
			/*cCliEnt*/,;	  		// 16-Codigo do cliente de entrega na nota fiscal de saida
			/*cLojEnt*/,;	  		// 17-Loja do cliente de entrega na nota fiscal de saida
			/*aTransp*/,;	  		// 18-Informacoes do transportador [01]-UF,[02]-TPTRANS
			/*lEmiteNF*/,;	  		// 19-Se esta emitindo nota fiscal ou cupom fiscal (Sigaloja)
			/*lCalcIPI*/,;    		// 20-Define se calcula IPI (SIGALOJA)
			/*cPedido*/,;     		// 21-Pedido de Venda
			/*cCliFat*/,;	  		// 22-Cliente do faturamento ( cCodCliFor é passado como o cliente de entrega, pois é o considerado na maioria das funções fiscais, exceto ao gravar o clinte nas tabelas do livro)
			/*cLojCFat*/,;    		// 23-Loja do cliente do faturamento
			/*nTotPed*/,;	  		// 24-Total do Pedido
			/*dDtEmiss*/,;	  		// 25-Data de emissão do documento inicialmente só é diferente de dDataBase nas notas de entrada (MATA103 e MATA910)
			/*cTpFrete*/,;    		// 26-Tipo de Frete informado no pedido
			/*lCalcPCC*/,;    		// 27-Indica se Calcula (PIS,COFINS,CSLL), independete da TES estar configurada para Gerar Duplicata (F4_DUPLIC)
			/*lCalcINSS*/,;   		// 28-Indica se Calcula (INSS), independete da TES estar configurada para Gerar Duplicata (F4_DUPLIC)
			/*lCalcIRRF*/,;   		// 29-Indica se Calcula (IRRF), independete da TES estar configurada para Gerar Duplicata (F4_DUPLIC)
			/*cTpCompl*/,;    		// 30-Tipo de Complemento
			/*cCltdest*/,;	  		// 31-Cliente de destino de transporte (Notas de entrada de transporte )
			/*cLjtdest*/,;    		// 32-Loja de destino de transporte (Notas de entrada de transporte )
			.T./*lCalcTG*/,;     	// 33-Flag para indicar se os tributos genéricos devem ou não ser calculados - deve ser passado como .T. somente após a preparação da rotina para gravação, visualização e exclusão dos tributos genéricos.
			/*nQtdItens*/,;   		// 34-Quantidade de itens no documento.
			/*lPlanilha*/)    		// 35-Indica se a chamada é realizada pela planilha financeira 
	//Incia natureza que será utilizada em uma situação de fechamento definitivo
	MaFisAlt("NF_NATUREZA",AllTrim(SuperGetMV('LT_NATGLT',,'222001')))

	If _nBase > 0 //Chamado no ALGT008, RGLT019 E MGLT027 onde não tenho os valores gravados na ZLF
		//Recupera a TES que deve ser utilizada caso não fosse uma previsão para simular os impostos que seriam gerados
		If SA2->A2_INDCP == '1' .And. SA2->A2_INCLTMG <> '1'//Cálculo sobre a produção (Calcula Gilrat e Senar) e sem TES de Incentivo à produção (ICMS Isento)
			_cTES := ZL8->ZL8_TES// TES Sem ICMS e com Gilrat
		ElseIf SA2->A2_INDCP == '2' .And. SA2->A2_INCLTMG <> '1'//Cálculo sobre a folha (Calcula apenas Senar) e sem TES de Incentivo à produção (ICMS Isento)
			_cTES := ZL8->ZL8_TESSEN// TES Sem ICMS e sem Gilrat
		ElseIf SA2->A2_INDCP == '1' .And. SA2->A2_INCLTMG == '1'//Cálculo sobre a produção (Calcula Gilrat e Senar) e TES de Incentivo à produção (calcula ICMS Tributado ou Outros)
			_cTES := ZL8->ZL8_TESIP1// TES com ICMS e com Gilrat
		ElseIf SA2->A2_INDCP == '2' .And. SA2->A2_INCLTMG == '1'//Cálculo sobre a folha (Calcula apenas Senar) e TES de Incentivo à produção (calcula ICMS Tributado ou Outros)
			_cTES := ZL8->ZL8_TESSE2// TES com ICMS e sem Gilrat
		EndIf
		MaFisAdd(ZL8->ZL8_SB1COD,		;// 1-Codigo do Produto ( Obrigatorio )
				_cTES,;	   				// 2-Codigo do TES ( Opcional )
				1,;  					// 3-Quantidade ( Obrigatorio )
				_nBase,;				// 4-Preco Unitario ( Obrigatorio )
				0,;						// 5-Valor do Desconto ( Opcional )
				"",;					// 6-Numero da NF Original ( Devolucao/Benef )
				"",;					// 7-Serie da NF Original ( Devolucao/Benef )
				0,;						// 8-RecNo da NF Original no arq SD1/SD2
				0,;						// 9-Valor do Frete do Item ( Opcional )
				0,;						// 10-Valor da Despesa do item ( Opcional )
				0,;						// 11-Valor do Seguro do item ( Opcional )
				0,;						// 12-Valor do Frete Autonomo ( Opcional )
				_nBase,;				//13-Valor da Mercadoria ( Obrigatorio )
				0)						// 14-Valor da Embalagem ( Opiconal )
	Else// chamado no MGLT009 onde tenho todos os eventos gravados na ZLF
		If _lNf1Item
			_cCampos := '% SUM(ZLF_TOTAL) VALOR %'
			_cGroup := '% GROUP BY ZLF_RETIRO, ZLF_RETILJ, ZLF_SETOR, ZL8_SB1COD, ZL8_TES, ZL8_TESSEN, ZL8_TESIP1, ZL8_TESSE2, B1_PRINCMG %'
		Else
			_cCampos := '% ZLF_TOTAL VALOR %'
			_cGroup := '%%'
		EndIf
		BeginSql alias _cAlias
			SELECT ZLF_RETIRO, ZLF_RETILJ, ZLF_SETOR, ZL8_SB1COD, ZL8_TES, ZL8_TESSEN, ZL8_TESIP1, ZL8_TESSE2, B1_PRINCMG, %exp:_cCampos%
			FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8, %Table:SB1% SB1
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZL8.D_E_L_E_T_ = ' '
			AND SB1.D_E_L_E_T_ = ' '
			AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
			AND ZL8.ZL8_FILIAL = %xFilial:ZL8%
			AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
			AND SB1.B1_COD = ZL8.ZL8_SB1COD
			AND ZLF.ZLF_RETIRO = %exp:SA2->A2_COD%
			AND ZLF.ZLF_RETILJ = %exp:SA2->A2_LOJA%
			AND ZLF.ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF.ZLF_SETOR  = %exp:ZL2->ZL2_COD%
			AND ZLF.ZLF_LINROT = %exp:ZL3->ZL3_COD%
			AND SubStr(ZLF.ZLF_RETIRO,1,1) = 'P'
			AND ZLF.ZLF_ORIGEM <> 'F'
			AND ZLF.ZLF_TP_MIX = 'L'
			AND ZL8_DEBCRE = 'C'
			/*AND ZLF.ZLF_ACERTO <> 'S'*/
			AND (ZL8.ZL8_SB1COD <> ' ' OR ZL8.ZL8_PREFIX <> ' ')
			%exp:_cGroup%
		EndSql

		While (_cAlias)->( !Eof() )
			//Recupera a TES que deve ser utilizada caso não fosse uma previsão para simular os impostos que seriam gerados
			If SA2->A2_INDCP == '1' .And. SA2->A2_INCLTMG <> '1'//Cálculo sobre a produção (Calcula Gilrat e Senar) e sem TES de Incentivo à produção (ICMS Isento)
				_cTES := (_cAlias)->ZL8_TES// TES Sem ICMS e com Gilrat
			ElseIf SA2->A2_INDCP == '2' .And. SA2->A2_INCLTMG <> '1'//Cálculo sobre a folha (Calcula apenas Senar) e sem TES de Incentivo à produção (ICMS Isento)
				_cTES := (_cAlias)->ZL8_TESSEN// TES Sem ICMS e sem Gilrat
			ElseIf SA2->A2_INDCP == '1' .And. SA2->A2_INCLTMG == '1'//Cálculo sobre a produção (Calcula Gilrat e Senar) e TES de Incentivo à produção (calcula ICMS Tributado ou Outros)
				_cTES := (_cAlias)->ZL8_TESIP1// TES com ICMS e com Gilrat
			ElseIf SA2->A2_INDCP == '2' .And. SA2->A2_INCLTMG == '1'//Cálculo sobre a folha (Calcula apenas Senar) e TES de Incentivo à produção (calcula ICMS Tributado ou Outros)
				_cTES := (_cAlias)->ZL8_TESSE2// TES com ICMS e sem Gilrat
			EndIf
			MaFisAdd((_cAlias)->ZL8_SB1COD,;// 1-Codigo do Produto ( Obrigatorio )
					_cTES,;	   				// 2-Codigo do TES ( Opcional )
					1,;  					// 3-Quantidade ( Obrigatorio )
					(_cAlias)->VALOR,;		// 4-Preco Unitario ( Obrigatorio )
					0,;						// 5-Valor do Desconto ( Opcional )
					"",;					// 6-Numero da NF Original ( Devolucao/Benef )
					"",;					// 7-Serie da NF Original ( Devolucao/Benef )
					0,;						// 8-RecNo da NF Original no arq SD1/SD2
					0,;						// 9-Valor do Frete do Item ( Opcional )
					0,;						// 10-Valor da Despesa do item ( Opcional )
					0,;						// 11-Valor do Seguro do item ( Opcional )
					0,;						// 12-Valor do Frete Autonomo ( Opcional )
					(_cAlias)->VALOR,;		//13-Valor da Mercadoria ( Obrigatorio )
					0)						// 14-Valor da Embalagem ( Opiconal )
			(_cAlias)->( DBSkip() )
		EndDo
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	_nValor := MaFisRet(,_cImp)

	//Finaliza o uso da funcao MatxFis, "zerando" os arrays de calculos interno
	MaFisEnd()
//Se já é definitivo, leio os impostos já calculados no documento de entrada
Else
	MaFisIniNF(1,; //Tipo de Nota Fiscal - [1] Nota Fiscal de Entrada -[2] Nota Fiscal de Saida
			SF1->(RECNO())) //Numero do Registro do Cabecalho da Nota Fiscal, ou o Alias da Tabela a ser considerada
	_nValor := MaFisRet(,_cImp)
	MaFisEnd()
EndIf

Return(_nValor)

/*
===============================================================================================================================
Programa----------: DescLeit
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 20/05/2019
Descrição---------: Retorna o volume de leite a ser descontado de acordo com a Crioscopia e Condenações
Parametros--------: Tipo da Faixa a ser filtrada. Se nenhuma For informada, todas referente ao mesmo assunto serão listadas.
					Valores são obtidos pelas tabelas posicionadas pelo MIX: SA2, ZLE, ZL2, ZL3, ZL8. Usado no ZL8_FORMUL
					_lLoja -> .T. -> Indica se a busca deve filtrar a loja ou se vai englobar todas as lojas do produtor
Retorno-----------: _nValor -> N ->Volume de leite a ser descontado
===============================================================================================================================
*/
User Function DESCLEIT(_cTipo As Character,_lLoja As Logical)

Local _cAlias	:= GetNextAlias() As Character
Local _nRet		:= 0 As Numeric
Local _cFiltro	:= "%" As Character
Default _cTipo	:= ""
Default _lLoja := .T.

If _lLoja
	_cFiltro += " AND ZLB.ZLB_RETILJ = '"+SA2->A2_LOJA+"' "
EndIf
If Empty(_cTipo)
	_cFiltro += "  AND ZLB.ZLB_TIPOFX IN ('000012','000013') %"
Else
	_cFiltro += "  AND ZLB.ZLB_TIPOFX = '" + _cTipo + "' %"
EndIf

//Na importação a planilha usada não tem dados de setor e linha. Como apenas uma coleta é feita por dia,
//consigo fazer os filtros usando a ZLD. O fechamento é por setor e linha, então preciso separar.
BeginSql alias _cAlias
	SELECT SUM(ZLB_VOLCRI) VOLCRI
	FROM %Table:ZLB% ZLB
	WHERE ZLB.D_E_L_E_T_ = ' ' 
	%exp:_cFiltro%
	AND ZLB.ZLB_FILIAL = %xFilial:ZLB%
	AND ZLB.ZLB_RETIRO = %exp:SA2->A2_COD%
	AND ZLB.ZLB_SETOR = %exp:ZL2->ZL2_COD% 
	AND ZLB.ZLB_DATA BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
	AND EXISTS (SELECT 1 FROM %Table:ZLD% ZLD
			WHERE ZLD.D_E_L_E_T_ = ' '
			AND ZLD.ZLD_FILIAL = ZLB.ZLB_FILIAL
			AND ZLB.ZLB_RETIRO = ZLD.ZLD_RETIRO
			AND ZLB.ZLB_RETILJ = ZLD.ZLD_RETILJ
			AND ZLB.ZLB_SETOR = ZLD.ZLD_SETOR
			AND ZLB.ZLB_DATA = ZLD.ZLD_DTCOLE
			AND ZLD.ZLD_LINROT = %exp:ZL3->ZL3_COD%)
EndSql

_nRet:= (_cAlias)->VOLCRI
(_cAlias)->(DBCloseArea())

Return _nRet

/*
===============================================================================================================================
Programa----------: GetTotCR
Autor-------------: Abrahao P. Santos
Data da Criacao---: 04/12/2008
Descrição---------: Funcao para retornar o valor de todos os Créditos do Produtor do MIX informado
Parametros--------: _cFilial,_cSetor,_cLinha,_cCodPro,_cLojPro,_cCodMix
Retorno-----------: _nValRet - valor Total do Crédito
===============================================================================================================================
*/
User Function GetTotCr(_cFilial As Character,_cSetor As Character,_cLinha As Character,_cCodPro As Character,_cLojPro As Character,_cCodMix As Character)

Local _aArea	:= FWGetArea() As Array
Local _nValRet	:= 0 As Numeric
Local _cFiltro	:= "%" As Character
Local _cAlias	:= GetNextAlias() As Character

// Obtendo valores de eventos de Crédito
If !Empty(_cSetor)
	_cFiltro += " AND ZLF_SETOR = '"+ _cSetor  +"' "
EndIf
If !Empty(_cLinha)
	_cFiltro += " AND ZLF_LINROT = '"+ _cLinha  +"' "
EndIf
If !Empty(_cCodPro)
	_cFiltro += " AND ZLF_A2COD = '"+ _cCodPro +"' "
EndIf
If !Empty(_cLojPro)
	_cFiltro += " AND ZLF_A2LOJA = '"+ _cLojPro +"' "
EndIf
_cFiltro += "%"

BeginSql alias _cAlias
	SELECT NVL(SUM(ZLF_TOTAL),0) TOTAL
	  FROM %Table:ZLF%
	 WHERE D_E_L_E_T_ = ' '
	   %exp:_cFiltro%
	   AND ZLF_FILIAL = %exp:_cFilial%
	   AND ZLF_CODZLE = %exp:_cCodMix%
	   AND ZLF_TP_MIX = 'L'
	   AND ZLF_ENTMIX = 'S'
	   AND ZLF_DEBCRE = 'C'
EndSql

_nValRet := (_cAlias)->TOTAL
(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return(_nValRet)

/*
===============================================================================================================================
Programa----------: LisLinha
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Valida se as linhas recebidos via parâmetros ou em memória, podem ser acessdos pelo usuário corrente
Parametros--------: _lFil -> .T. -> indica se filtra setores da filial corrente
					_cSetor -> C -> Indica os setores caso deseje filtrar algum
Retorno-----------: _cLinhas -> lista com os setores que o usuário tem acesso
===============================================================================================================================
*/
User Function LisLinha(_lFil As Logical,_cSetor As Character)

Local _cFiltro	:= "%" As Character
Local _cAlias 	:= GetNextAlias() As Character
Local _cLinhas	:= "" As Character

Default _lFil	:= .F.
Default _cSetor := ""

If _lFil
	_cFiltro += "AND ZL3_FILIAL = '"+xFilial("ZL3")+"'"
EndIf
If !Empty(_cSetor)
	_cFiltro += "AND ZLV_SETOR = '"+_cSetor+"'"
EndIf
_cFiltro += "%"
If Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	BeginSql alias _cAlias
		SELECT LISTAGG(LINHA, ';') WITHIN GROUP(ORDER BY ZLV_SETOR) LINHA  FROM 
		(SELECT ZLV_SETOR, Case WHEN LISTAGG(ZLR_LINHA, ';') WITHIN GROUP(ORDER BY ZLR_LINHA) IS NULL THEN
		(SELECT LISTAGG(ZL3_COD, ';') WITHIN GROUP(ORDER BY ZL3_COD)
			FROM %Table:ZL3%
			WHERE D_E_L_E_T_ = ' '
		AND ZL3_SETOR = ZLV_SETOR)
		Else
		LISTAGG(ZLR_LINHA, ';') WITHIN GROUP(ORDER BY ZLR_LINHA)
		END LINHA
		FROM %Table:ZL2% ZL2, %Table:ZLV% ZLV, %Table:ZLR% ZLR
		WHERE ZLV.D_E_L_E_T_ =' '
		AND ZL2.D_E_L_E_T_ = ' '
		AND ZLR.D_E_L_E_T_ (+) = ' '
		AND ZL2_COD = ZLV_SETOR
		%exp:_cFiltro%
		AND ZLV_SETOR = ZLR_SETOR (+)
		AND ZLV_CODUSU = ZLR_CODUSU (+)
		AND ZLV_CODUSU = %Exp:RetCodUsr()%
		GROUP BY ZLV_SETOR)
	EndSql
	_cLinhas := IIf(Empty((_cAlias)->LINHA),"XXXXXX",(_cAlias)->LINHA)
	(_cAlias)->(DBCloseArea())
EndIf
//Retorna vazio quando o usuário tem acesso à todas as linhas. Quando não tem, mas não localizou nenhuma linha
//permitida, retorna um código inexistente para que não exiba as informações idenvidamente
Return (_cLinhas)

/*
===============================================================================================================================
Programa----------: GetEvtFrt
Autor-------------: Abrahao P. Santos
Data da Criacao---: 01/12/2008
Descrição---------: Retorna valor total dos eventos do fretista
Parametros--------: _cFilial,_cSetor,_cLinha,_cFornece,_cLoja,_cEvento,_cCodMix
Retorno-----------: Valor total do evento
===============================================================================================================================
*/
User Function getEvtFrt(_cFilial As Character,_cSetor As Character,_cLinha As Character,_cFornece As Character,_cLoja As Character,_cEvento As Character,_cCodMix As Character)

Local _aArea  	:= FWGetArea() As Array
Local _cAlias	:= GetNextAlias() As Character
Local _nValRet 	:= 0 As Numeric

BeginSql alias _cAlias
	SELECT NVL(SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END),0) TOTAL
	  FROM %Table:ZLF%
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLF_EVENTO = %exp:_cEvento%
	   AND SubStr(ZLF_A2COD, 1, 1) = 'G'
	   AND ZLF_FILIAL = %exp:_cFilial%
	   AND ZLF_CODZLE = %exp:_cCodMix%
	   AND ZLF_SETOR = %exp:_cSetor%
	   AND ZLF_LINROT = %exp:_cLinha%
	   AND ZLF_A2COD = %exp:_cFornece%
	   AND ZLF_A2LOJA = %exp:_cLoja%
EndSql

_nValRet:= (_cAlias)->TOTAL
(_cAlias)->(DBCloseArea())
FWRestArea(_aArea)

Return(_nValRet)

/*
===============================================================================================================================
Programa----------: ImpParam
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Função para imprimir página de parâmetros em relatórios usando FWMSPrinter
Parametros--------: oPrinter,nLin,cPerg,_aCol,oFontL
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ImpParam(_oPrinter As Object,_nLin As Numeric,_cPerg As Character,_aCol As Array,_oFontL As Object)

Local _cVlrParam:= "" As Character
Local _nAux     := 0 As Numeric
Local _nX		:= 0 As Numeric
Local _nLimCol	:= 100 As Numeric//Quantidade de caracteres para quebra de Linha
Local _oSX1 	:= FWSX1Util():New() As Object

_oSX1:AddGroup(_cPerg)
_oSX1:SearchGroup()

For _nX:=1 to Len(_oSX1:aGrupo[1][2])
	_nAux:= 1
	_oPrinter:Say (_nLin,_aCol[1],"Pergunta " + _oSX1:aGrupo[1][2][_nX]:CX1_ORDEM + ' : ' + AllTrim(_oSX1:aGrupo[1][2][_nX]:CX1_PERGUNT),_oFontL)
		//Verifica se eh combo
	If _oSX1:aGrupo[1][2][_nX]:CX1_GSC == 'C'
		_cVlrParam:= &("_oSX1:aGrupo[1][2][_nX]:CX1_DEF"+ StrZero(&(_oSX1:aGrupo[1][2][_nX]:CX1_VAR01),2))
	Else
		Do Case
			Case _oSX1:aGrupo[1][2][_nX]:CX1_TIPO == 'C'
		 		_cVlrParam:= &(_oSX1:aGrupo[1][2][_nX]:CX1_VAR01)
			Case _oSX1:aGrupo[1][2][_nX]:CX1_TIPO == 'D'
				_cVlrParam:= DToC(&(_oSX1:aGrupo[1][2][_nX]:CX1_VAR01))
			Case _oSX1:aGrupo[1][2][_nX]:CX1_TIPO == 'N'
				_cVlrParam:= AllTrim(Str(&(_oSX1:aGrupo[1][2][_nX]:CX1_VAR01)))
		EndCase
	EndIf

	While _nAux <= Len(AllTrim(_cVlrParam))
		_oPrinter:Say(_nLin,160,SubStr(AllTrim(_cVlrParam),_nAux,_nLimCol),_oFontL)
		_nLin+= 10
		_nAux+= _nLimCol
	EndDo
	
	If Len(AllTrim(_cVlrParam)) == 0
		_nLin+= 10
	EndIf
Next _nX

_oPrinter:EndPage()

Return

/*
===============================================================================================================================
Programa----------: CalcInc
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 24/02/2022
Descrição---------: Função para cálculo do Incentivo à Produção em MG de acordo com o configurador de tributos. Se a filial 
					possui incetivo à produção, ajusto o cadastro do produtor quando ele tiver direito ao incentivo (soma da 
					produção do ano todo para o mesmo CNPJ e IE For inferior ao valor do parâmetro)
Parametros--------: Tabelas posicionadas: SA2, ZLE
					_nTipo -> N -> 1-Primeira parte do processo onde ajusto os cadastros 2-Restauro as informações ajustadas
					_nVolIncP -> N -> Volume anual que indica quando deve ou não ser calculado o incentivo
					_lCalIncP -> L -> Indica se será feito o cálculo do incentivo
					_nRecPrd -> N -> RECNO da SA2 para voltar o bkp da informação
					_nRecINS -> N -> RECNO da F22 referente à regra do INSS para voltar o bkp da informação
					_nRecGil -> N -> RECNO da F22 referente à regra do Gilrat para voltar o bkp da informação
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CalcInc(_nTipo As Numeric,_nVolIncP As Numeric,_lCalIncP As Logical,_nRecPrd As Numeric,_nRecINS As Numeric,_nRecGil As Numeric)

If _nTipo == 1
	DBSelectArea("F22")
	F22->(DBSetOrder(1))
	If SubStr(SA2->A2_COD,1,1) == 'P' .And. SA2->A2_TIPO == 'F' .And. F22->(DBSeek(xFilial("F22")+SuperGetMV("LT_REGINCP",.F.,"")+"1"+SA2->(A2_COD+A2_LOJA)))
		_lCalIncP := .T.
		DBSelectArea("F28")
		F28->(DBSetOrder(1))
		//Se a filial possui incetivo à produção, ajusto o cadastro do produtor quando ele tiver direito ao incentivo (soma da produção do ano todo para o mesmo CNPJ e IE For inferior ao valor do parâmetro)	
		If !U_GLTVANO(_nVolIncP,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM)
			SA2->(RecLock("SA2",.F.))
			SA2->A2_INCLTMG := '2' //1-Sim,2-Não
			SA2->(MSUnLock())
			//Apago o registro da regra no configurador de tributo para que não seja calculada nenhuma exceção fiscal
			_nRecPrd := F22->(RECNO())
			F22->(RecLock("F22",.F.))
			F22->(DBDelete())
			F22->(MSUnLock())
		Else
			If SA2->A2_INDCP == '2' //Se o cálculo é sobre a Folha, só devo calcular o Senar
				//Apago a regra do 000001-INSS pois o configurador de tributos ignora o cadastro do fornecedor
				If F28->(DBSeek(xFilial("F28")+SuperGetMV("LT_INSINCP",.F.,"")))
					_nRecINS := F28->(RECNO())
					F28->(RecLock("F28",.F.))
					F28->(DBDelete())
					F28->(MSUnLock())
				EndIf
				//Apago a regra do 000002-Gilrat pois o configurador de tributos ignora o cadastro do fornecedor
				If F28->(DBSeek(xFilial("F28")+SuperGetMV("LT_GILINCP",.F.,"")))
					_nRecGil := F28->(RECNO())
					F28->(RecLock("F28",.F.))
					F28->(DBDelete())
					F28->(MSUnLock())
				EndIf
			EndIf
		EndIf
	Else
		_lCalIncP := .F.
	EndIf

Else//Se a filial possui incetivo à produção e eu ajustei o campo para o cálculo, volto o campo ao conteúdo original
	If SA2->A2_INCLTMG == '2'
		SA2->(RecLock("SA2",.F.))
		SA2->A2_INCLTMG := '1' //1-Sim,2-Não
		SA2->(MSUnLock())
		If _nRecPrd > 0
			Set Deleted Off //Exibe registros deletados
			F22->(DBGoTo(_nRecPrd))
			F22->(RecLock("F22",.F.))
			F22->(DBRecall())//Recupero o registro deletado para não ser necessário incluir um novo toda vez
			F22->(MSUnLock())
			Set Deleted On //Restauro a não exibição de registros deletados
		EndIf
	EndIf

	If SA2->A2_INDCP == '2' //Se o cálculo é sobre a Folha, só devo calcular o Senar
		Set Deleted Off //Exibe registros deletados
		If _nRecINS > 0 
			F28->(DBGoTo(_nRecINS))//Restauro o cálculo do INSS
			F28->(RecLock("F28",.F.))
			F28->(DBRecall())//Recupero o registro deletado para não ser necessário incluir um novo toda vez
			F28->(MSUnLock())
		EndIf
		If _nRecGil > 0
			F28->(DBGoTo(_nRecGil))//Restauro o cálcil do Gilrat
			F28->(RecLock("F28",.F.))
			F28->(DBRecall())//Recupero o registro deletado para não ser necessário incluir um novo toda vez
			F28->(MSUnLock())
		EndIf
		Set Deleted On //Restauro a não exibição de registros deletados
	EndIf
EndIf
Return


/*
===============================================================================================================================
Programa----------: EnvMail
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 08/09/2023
Descrição---------: Rotina para envio de e-mail
Parametros--------: _cMensagem -> Mensagem do e-mail
					_cFrom -> remetente
					_cTO -> destinatário
					_cCC -> Indica os e-mails para o qual se deseja enviar uma determinada mensagem. Os endereços estarão na seção 'Com Cópia' da mensagem.
					_cBCC -> Indica os e-mails para o qual se deseja enviar uma determinada mensagem. Os endereços estarão na seção 'Com Cópia Oculta' da mensagem.
					_cReplyTo -> Indica os endereços de e-mail que serão colocados como uma possível resposta para uma mensagem
					_cAssunto -> Assunto
					_cErro -> Retorna Mensagem de erro
					_aAttach -> Lista de anexos para serem enviados
Retorno-----------: _lRet -> .T./.F. indica se houve sucesso no envio do e-mail
===============================================================================================================================
*/
User Function EnvMail(_cMensagem As Character,_cFrom As Character,_cTO As Character,_cCC As Character,_cBCC As Character,;
					_cReplyTo As Character,_cAssunto As Character,_cErro As Character,_aAttach As Array)

Local _lRet			:= .T. As Logical
Local _cSMTPServer	:= GETMV("MV_RELSERV",.F.,"") As Character //mail.italac.com.br:465
Local _cSMTPUser 	:= GETMV("MV_RELACNT",.F.,"") As Character //workflow@italac.com.br
Local _cSMTPPass 	:= GETMV("MV_RELPSW",.F.,"") As Character //WorkF@#3121
Local _lUseTLSMail 	:= SuperGetMv("MV_RELTLS",,.F.) As Logical//.F.
Local _lUseSSLMail 	:= SuperGetMv("MV_RELSSL",,.F.) As Logical// .T.
Local _nSMTPPort	:= If(GETMV("MV_PORSMTP") == 0, 25, GETMV("MV_PORSMTP")) As Numeric
Local _oMail		:= Nil As Object
Local _oMessage 	:= Nil As Object
Local _nErro		:= 0 As Numeric
Local _lRelAuth 	:= GetMv("MV_RELAUTH",.F., .F.) As Logical
Local _nX			:= 0 As Numeric
Local _cDrive		:= "" As Character
Local _cDir			:= "" As Character
Local _cNome		:= "" As Character
Local _cExt			:= "" As Character
Local _cMsgAux		:= "" As Character
Local _nPos			:= 0 As Numeric
Default _cMensagem	:= ""
Default _cFrom		:= GETMV("MV_RELFROM",.F.,"") //workflow@italac.com.br
Default _cTO 		:= SuperGetMV("MV_RESMAIL",,"")
Default _cCC		:= ""
Default _cBCC		:= ""
Default _cReplyTo	:= ""
Default _cAssunto	:= ""
Default _cErro		:= ""
Default _aAttach 	:= {}

//Por padrão os ambientes de teste sempre irão direcionar os e-mails para a conta de sistema e do usuário logado
// ao invés dos destinatários enviados
If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
	_cAssunto := GetEnvServer()+' - ' + _cAssunto
		
	// Tabela com informações do ambiente
	_cMsgAux := '<tr><td class="itens" width="160" style="white-Space: nowrap;"><b>Ambiente:</b></td>'
	_cMsgAux += '<td class="itens" align="left">[' + GetEnvServer() + ']</td></tr>'

	// Tabela com destinatários originais, apenas se For redirecionado
	_cMsgAux += '<tr><td class="itens" width="160" style="white-Space: nowrap;"><b>TO original:</b></td>'
	_cMsgAux += '<td class="itens" align="left">' + _cTO + '</td></tr>'

	_cMsgAux += '<tr><td class="itens" width="160" style="white-Space: nowrap;"><b>CC original:</b></td>'
	_cMsgAux += '<td class="itens" align="left">' + _cCC + '</td></tr>'

	_cMsgAux += '<tr><td class="itens" width="160" style="white-Space: nowrap;"><b>BCC original:</b></td>'
	_cMsgAux += '<td class="itens" align="left">' + _cBCC + '</td></tr>'

	_cMsgAux += '<tr><td class="itens" width="160" style="white-Space: nowrap;"><b>ReplyTo original:</b></td>'
	_cMsgAux += '<td class="itens" align="left">' + _cReplyTo + '</td></tr>'

	_cMsgAux := '<table border="1" style="font-family: Arial; font-size: 12px; border-collapse: collapse;" width="100%">' + ;
            _cMsgAux + '</table><br>'


	// Reconstrói o corpo do e-mail
	If (_nI := At("</BODY>", Upper(_cMensagem))) > 0
		_cMensagem := SubStr(_cMensagem, 1, _nPos - 1) + _cMsgAux + SubStr(_cMensagem, _nPos)
	Else
		// Se não achou o </body>, apenas concatena no final
		_cMensagem += _cMsgAux
	EndIf

	If SuperGetMv("IT_EMAILTR",.F.,.T.)
		//Se For schedule ou usuário comum, envia para todos. Se não For, apenas para quem estiver testando
		If FWGetRunSchedule() .Or. !FwIsAdmin()
			_cTO := 'sistema@italac.com.br'
			_cCC := AllTrim(UsrRetMail(__cUserId))
			_cBCC := ''
			_cReplyTo := ''
		Else
			_cTO := AllTrim(UsrRetMail(__cUserId))
			_cCC := ''
			_cBCC := ''
			_cReplyTo := ''
		EndIf
	EndIf
EndIf

//Conforme RFC 5322 seção 3.4, deve-se utilizar a vírgula (,) para separar lista de e-mails.
//Criado temporariamente até a TOTVS tratar a questão
If "AMAZON" $ Upper(_cSMTPServer)
	_cTO := StrTran(_cTO,";",",")
	_cCC := StrTran(_cCC,";",",")
	_cBCC := StrTran(_cBCC,";",",")
	_cReplyTo := StrTran(_cReplyTo,";",",")
EndIf

//Tratamento para caso a porta esteja apenas no parametro MV_RELSERV.
If (_nPos := AT(':',_cSMTPServer)) > 0 
 	_nSMTPPort 		:= Val(SubStr(_cSMTPServer, _nPos + 1,Len(_cSMTPServer)))
 	_cSMTPServer := SubStr(_cSMTPServer, 0, _nPos - 1)  
EndIf

If !Empty(_cTO) //Envio de e-mail só ocorre se existirem destinatários

	_oMail := TMailManager():New() //Iniciando conexão com o servidor de e-mails
	
	_oMail:SetUseSSL(_lUseSSLMail)
	_oMail:SetUseTLS(_lUseTLSMail)

	//Cria a conexão com o server STMP ( Envio de e-mail )
	_oMail:Init( '', _cSMTPServer , _cSMTPUser, _cSMTPPass, 0, _nSMTPPort )

	//seta um tempo de time out com servidor de 1min
	_nErro := _oMail:SetSmtpTimeOut( 60 )
  	If _nErro <> 0
		_cErro := "Falha ao setar o time out. Código do erro: "+Str(_nErro,6) +" / "+ _oMail:GetErrorString(_nErro)
		_lRet:= .F.
  	Else
		//realiza a conexão SMTP
		_nErro := _oMail:SmtpConnect()
		If _nErro <> 0
			_cErro := "Falha ao conectar. Código do erro: "+Str(_nErro,6) +" / "+ _oMail:GetErrorString(_nErro)
			_lRet:= .F.
		EndIf
	EndIf
	If _lRet .And._lRelAuth //Autenticando o usuário no servidor de e-mails
		//Autenticando Usuario
		_nErro := _oMail:SmtpAuth(_cSMTPUser ,_cSMTPPass)
		If _nErro <> 0
			_cErro := "Erro de Autenticacao. Código do erro: "+Str(_nErro,6) +" / "+ _oMail:GetErrorString(_nErro)
			_lRet := .F.
		EndIf
	EndIf

	If _nErro <> 0
		// Recupera erro
		_cErro := "Erro de Autenticacao "+Str(_nErro,4)+' ('+_oMail:GetErrorString(_nErro)+')'
		_lRet := .F.
		_oMail:SMTPDisconnect()
	EndIf

	//Criando o objeto da mensagem do e-mail
	_oMessage := TMailMessage():New()
	_oMessage:Clear()      
	_oMessage:cFrom		:= Lower(_cFrom)
	_oMessage:cTo		:= Lower(_cTo)
	_oMessage:cCC		:= Lower(_cCC)
	_oMessage:cBCC		:= Lower(_cBCC)
	_oMessage:cReplyTo	:= Lower(_cReplyTo)
	_oMessage:cSubject	:= FWHttpEncode(_cAssunto)
	_oMessage:cBody		:= _cMensagem
	_oMessage:MsgBodyType( "text/html" )

	For _nX := 1 To Len(_aAttach)
		_cNome:=""
		//Adiciona um attach
		If _oMessage:AttachFile(_aAttach[_nX]) < 0
			_cErro := "Erro ao atachar o arquivo"
			_lRet := .F.
			Exit
		Else
			SplitPath( _aAttach[_nX], @_cDrive, @_cDir, @_cNome, @_cExt )
			_cNome += _cExt
			//adiciona uma tag informando que é um attach e o nome do arq
			//modo attachment ao contrário já indica para o browser fornecer diretamente a janela de download para baixar o arquivo
			//modo inline, o browser/navegador deve preferencialmente tentar abrir o conteúdo enviado nele próprio
			_oMessage:AddAtthTag('Content-Disposition: attachment; filename="' + _cNome + '"')
		EndIf
	Next _nX
	
	If _lRet
		_nErro := _oMessage:Send(_oMail)

		If _nErro <> 0
			_cErro := "Erro de Envio SMTP "+Str(_nErro,4)+" ("+_oMail:GetErrorString(_nErro)+")"
			_lRet := .F.
		EndIf

		//Desconectando do SMTP
		_nErro := _oMail:SMTPDisconnect()
		If _nErro <> 0
			_cErro := "Erro ao desconectar SMTP "+Str(_nErro,4)+" ("+_oMail:GetErrorString(_nErro)+")"
			_lRet := .T. // O e-mail chegou a ser enviado, então não é um grande problema.
		EndIf
	EndIf
Else
	_cErro := "Destinatario não informado."
	_lRet := .F.
EndIf

Return _lRet


/*
===============================================================================================================================
Programa----------: AdicVol
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/12/2023
Descrição---------: Função para retornar o valor do evento Adicional de Volume
Parametros--------: _lLoja -> L -> Indica se o volume analisado deve levar em conta a loja corrente ou todas as lojas do 
					produtor
					_cFaixa -> C -> Faixa que seja analisada
Retorno-----------: _nValEve -> N -> Valor apurado para o evento
===============================================================================================================================
*/
User Function AdicVol(_lLoja As Logical,_cFaixa As Character)

Local _nVolLiq := 0 As Numeric
Local _nVolTot := 0 As Numeric
Local _nValEve := 0 As Numeric
Default _lLoja := .T.

_nVolLiq := U_VolLeite(cFilAnt,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,SA2->A2_LOJA,,,1)-U_DescLeit(,.T.)
If !_lLoja
	_nVolTot := U_VolLeite(cFilAnt,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,ZL2->ZL2_COD,ZL3->ZL3_COD,SA2->A2_COD,,,,1)-U_DescLeit(,_lLoja)
Else
	_nVolTot := _nVolLiq
EndIf
_nValEve := _nVolLiq*U_GetFaixa(xFilial("ZLA"),ZL2->ZL2_COD,_cFaixa,U_MedLeite(_cFaixa,_nVolTot))

Return _nValEve
