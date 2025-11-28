/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |18/08/2015| Chamado 11417. Correção da chamada do MsgBox padronizando para o MessageBox.                   
Alex Wallauer |21/02/2024| Chamado 46236. Andre. Ajustes do gatilhos dos campos: BC_PRODUTO-504,BC_QUANT-502,BC_QTSEGUM-502.
André Lisboa  |13/03/2024| Chamado 46587. Gatilho para grupo de produto "leite em po" para produto destino "Residuo lacteo"
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AEST034
Autor-----------: Alex Wallauer 
Data da Criacao-: 21/02/2024
Descrição-------: Rotina para preencher os Gatilhos dos campos BC_PRODUTO-502 / BC_PRODUTO-504 / BC_QUANT-502 / BC_QTSEGUM-502.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AEST034(cContraDominio)

Local _aArea	:= FWGetArea()
//Local cPrdDstP	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "BC_CODDEST" } )
//Local cPrdDst	:= aCols[N][cPrdDstP]
//Local cPrdOriP	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "BC_PRODUTO" } )
//Local cPrdOri	:= aCols[N][cPrdOriP]
Local _cGrpPrd	:= GETMV( "IT_GRPSUCA" )
Local _cPrdSuc	:= GETMV( "IT_PRDSUCA" )
//Local cMotivo	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "BC_MOTIVO" } )
//Local cMot		:= aCols[N][cMotivo]

//If AllTrim(cPrdOri) $ cGrpPrd .And. cMot <> "PP"
//	cPrdDst := cPrdSuc
//ElseIf cMot <> "PP"
//	cPrdDst := ""
//	MessageBox( "Se o apontamento de perda gerar sucata, não esqueça de preencher o produto destino!" , "Atenção!" , 48 )
//EndIf
//If cMot == "PP"
//   cPrdDst := ""
//EndIf
SC2->(DBSetOrder(1))//SC2->C2_FILIAL+SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN
_lOPAberta:=.T.
If xFilial("SC2")+CORDEMP <> SC2->C2_FILIAL+SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN
   If SC2->(DBSeek(xFilial("SC2")+CORDEMP)) 
      _lOPAberta:=Empty(SC2->C2_DATRF)
   EndIf
Else
   _lOPAberta:=Empty(SC2->C2_DATRF)
EndIf


Do Case 
   Case cContraDominio ="BC_LOCAL"   // Gatilho do campo BC_PRODUTO 502
        _cRet:=If(_lOPAberta, GdFieldGet("BC_LOCAL"  ,n) , "34")
   Case cContraDominio ="BC_CODDEST" // Gatilho do campo BC_PRODUTO 504
//        _cRet:=If(_lOPAberta, If(trim(GdFieldGet("BC_PRODUTO",n)) $ _cGrpPrd,_cPrdSuc ,(GdFieldGet("BC_CODDEST",n))),If(trim(GdFieldGet("BC_PRODUTO",n)) $ _cGrpPrd,_cPrdSuc ,(GdFieldGet("BC_CODDEST",n))))
          _cRet:=If(_lOPAberta, If(trim(GdFieldGet("BC_PRODUTO",n)) $ _cGrpPrd,If(U_ITMsg('Produto destino "Resíduo lácteo"','Atenção!','Gravar dados para destino "Resíduo lácteo"?',3,2,2,,"GRAVAR","VOLTAR"),_cPrdSuc ,""),""),If(trim(GdFieldGet("BC_PRODUTO",n)) $ _cGrpPrd,If(U_ITMsg('Produto destino "Resíduo lácteo"','Atenção!','Gravar dados para destino "Resíduo lácteo"?',3,2,2,,"GRAVAR","VOLTAR"),_cPrdSuc ,GdFieldGet("BC_PRODUTO",n)),GdFieldGet("BC_PRODUTO",n)))   
   Case cContraDominio ="BC_QTDDEST" // Gatilho do campo BC_QUANT   502
        _cRet:=If(_lOPAberta, GdFieldGet("BC_QTDDEST",n) , GdFieldGet("BC_QUANT",n) )
   Case cContraDominio ="BC_QTDDES2" // Gatilho do campo BC_QTSEGUM 502
        _cRet:=If(_lOPAberta, GdFieldGet("BC_QTDDES2",n) , GdFieldGet("BC_QTSEGUM",n) )
EndCase

/*			If 	TRIM(GdFieldGet("BC_CODDEST",_nI)) == TRIM(_cPrdSuc)
				If !U_ITMsg('Produto destino "Resíduo lácteo"','Atenção!','Gravar dados para destino "Resíduo lácteo"?',3,2,2,,"GRAVAR","VOLTAR")
					_lRet:=.F.
				EndIf	
			EndIf	*/

FWRestArea(_aArea)

Return( _cRet )
