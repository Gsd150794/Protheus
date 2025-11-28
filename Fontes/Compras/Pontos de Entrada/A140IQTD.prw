/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |27/01/2020| Chamado 31828. Corrigido cálculo da segunda unidade de medida.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A140IQTD
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 16/01/2020
Descrição---------: O Ponto de entrada é executado durante a inclusão dos itens do documento. Permite alterar os campos de 
                    quantidade, valor unitário, total e quantidade da segunda unidade de medida na importação do documento.
Parametros--------: ParamIXB[01] -> C -> Produto
                    ParamIXB[02] -> C -> Unidade de medida
                    ParamIXB[03] -> C -> Segunda unidade de medida
                    ParamIXB[04] -> N -> Quantidade da segunda unidade de medida
                    ParamIXB[05] -> N -> Quantidade
                    ParamIXB[06] -> N -> Preço unitário
                    ParamIXB[07] -> N -> Total
                    ParamIXB[08] -> L -> .T. - Utiliza 2ª unidade de medida / .F. - Não utiliza 2ª unidade de medida
                    ParamIXB[09] -> C -> Fornecedor
                    ParamIXB[10] -> C -> Loja
                    ParamIXB[11] -> C -> Documento
					ParamIXB[12] -> C -> Série
					ParamIXB[13] -> C -> Tipo do Documento
					ParamIXB[14] -> L -> .T. = Alias SA7 (Cliente) / .F. = Alias SA5 (Fornecedor)
					ParamIXB[15] -> O -> XML do documento
Retorno-----------: aRet[1] -> N -> Quantidade
                    aRet[2] -> N -> Preço unitário
                    aRet[3] -> N -> Total
                    aRet[4] -> N -> Quantidade segunda unidade de medida
===============================================================================================================================
*/
User Function A140IQTD

Local _cAlias   := IIf(ParamIXB[14]==.T.,"SA7","SA5")
Local _cFornece := ParamIXB[09]
Local _cLoja    := ParamIXB[10]
Local _cProduto := ParamIXB[01]
Local _nVUnit   := ParamIXB[06]
Local _nQuant   := ParamIXB[05]
Local _nTotal   := ParamIXB[07]
Local _cSegUm   := ParamIXB[03]
Local _nQtSegun := ParamIXB[04]
Local _aRet     := {_nQuant,_nVUnit,_nTotal,_nQtSegun}
Local _nNewQuant:= ParamIXB[05]

DBSelectArea(_cAlias)
(_cAlias)->( DBSetOrder(1) )
SB1->( DBSetOrder(1) )
SB1->(DBSeek( xFilial("SB1") + _cProduto))
If	(_cAlias)->( DBSeek( xFilial(_cAlias) + _cFornece + _cLoja + _cProduto ) )	.And.;
    !Empty( &(_cAlias +'->'+ SubStr(_cAlias,2,2) +'_I_FTCON') )	.And. !Empty( &(_cAlias +'->'+ SubStr(_cAlias,2,2) +'_I_TPCON') )

		If &( _cAlias+'->'+ SubStr(_cAlias,2,2) +'_I_TPCON' ) == 'D'
            _nNewQuant := _nQuant / &(_cAlias+'->'+ SubStr(_cAlias,2,2) +'_I_FTCON')
            _aRet[1] := Round( _nNewQuant, GetSX3Cache("DT_QUANT","X3_DECIMAL"))
			_aRet[2] := Round( _nTotal / _nNewQuant, GetSX3Cache("DT_VUNIT","X3_DECIMAL"))
		Else
            _nNewQuant := _nQuant * &(_cAlias+'->'+ SubStr(_cAlias,2,2) +'_I_FTCON')
            _aRet[1] := Round( _nNewQuant, GetSX3Cache("DT_QUANT","X3_DECIMAL"))
			_aRet[2] := Round( _nTotal / _nNewQuant, GetSX3Cache("DT_VUNIT","X3_DECIMAL"))
		EndIf
        If !Empty(_cSegUm) .And. SB1->B1_TIPCONV == 'D'
            _aRet[4] := Round(_nNewQuant/SB1->B1_CONV, GetSX3Cache("DT_QTSEGUM","X3_DECIMAL"))
        ElseIf !Empty(_cSegUm) .And. SB1->B1_TIPCONV == 'M'
            _aRet[4] := Round(_nNewQuant*SB1->B1_CONV, GetSX3Cache("DT_QTSEGUM","X3_DECIMAL"))
        EndIf
EndIf

Return _aRet
