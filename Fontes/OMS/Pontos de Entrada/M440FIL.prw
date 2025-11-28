/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |11/08/2016| Chamado 16548. Projeto de unificação de pedidos de troca nota
Josué Danich  |31/03/2017| Chamado 19537. Incluido filtros por filial atual e data de emissão.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

/*
===============================================================================================================================
Programa----------: M440FIL
Autor-------------: Fabiano Dias
Data da Criacao---: 02/06/2010
Descrição---------: PE executado antes da montagem da tela de liberacao de Pedido de Venda para filtrar pedidos
Parametros--------: Padrão
Retorno-----------: Este ponto deve retornar uma string contendo uma condição de filtro em sintaxe xBase para a tabela SC5.
===============================================================================================================================
*/
User Function M440FIL()
 
Local _cPerg	:= "M440FIL"
Local _cFiltro	:= ""//" .T. "
Local _aAux		:= {}
Local _nI		:= 0
Local _lresp := .F.

_lresp := Pergunte( _cPerg , .T. )

If !_lresp

	MV_PAR01:=MV_PAR02:=MV_PAR03:=MV_PAR04:=MV_PAR05:=MV_PAR16:=MV_PAR17:=Space(100)
    MV_PAR06:=Space(6)
    MV_PAR07:=2
    MV_PAR08:=2
    MV_PAR09:= DDATABASE - 180
    MV_PAR10:= DDATABASE
    MV_PAR11:= 1
    MV_PAR12:= Space(Len(SC5->C5_NUM))
    MV_PAR13:= Space(Len(SC5->C5_NUM))
	
EndIf

//====================================================================================================
//Pode Adicionar filial  para melhorar a performance
//====================================================================================================
If MV_PAR11 != 2

  If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf 
   
	_cFiltro += "  C5_FILIAL == '" + cfilant + "')"
	
EndIf

//====================================================================================================
// Filtra por data de emissão do pedido
//====================================================================================================
If !Empty(MV_PAR09) .And. !Empty(MV_PAR10) .And. _lresp

  If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf 
	
	_cFiltro += " C5_EMISSAO >= SToD('"+DToS(MV_PAR09)+"') .And. C5_EMISSAO <= SToD('"+DToS(MV_PAR10)+"') ) "

EndIf

//====================================================================================================
// Filtra por data de entrega do pedido
//====================================================================================================
If !Empty(MV_PAR14) .And. !Empty(MV_PAR15) .And. _lresp

  If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf 
	
	_cFiltro += " C5_I_DTENT >= SToD('"+DToS(MV_PAR14)+"') .And. C5_I_DTENT <= SToD('"+DToS(MV_PAR15)+"') ) "

EndIf

//====================================================================================================
//Verifica os Filtros informados pelo usuário
//====================================================================================================
// Por estado
//====================================================================================================
If !Empty(MV_PAR01)  

    If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf 
	
	_aAux:= StrTokArr( AllTrim(MV_PAR01) , ";" )
	
	For _nI := 1 to Len(_aAux)
		
		_cFiltro += " C5_I_EST == '" + _aAux[_nI] +"'"
		
		If _nI <> Len(_aAux)
			_cFiltro += " .Or. "
		EndIf
		
	Next _nI
	
	_cFiltro += " )"

EndIf

//====================================================================================================
// Por município
//====================================================================================================
If !Empty(MV_PAR02)
    
    If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf
	
	_aAux := StrTokArr( AllTrim(MV_PAR02) , ";" )
	
	For _nI := 1 to Len(_aAux)
		
		_cFiltro += "C5_I_CMUN == '"+ _aAux[_nI] +"'"
		
		If _nI <> Len(_aAux)
			_cFiltro += " .Or. "
		EndIf
		
	Next _nI
	
 	_cFiltro += " )"
 	
EndIf

//====================================================================================================
// Por vendedor
//====================================================================================================
If !Empty(MV_PAR03)
    
    If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf 
	
	_aAux := StrTokArr( AllTrim(MV_PAR03) , ";" )
	
	For _nI := 1 to Len(_aAux)
		
		_cFiltro += "C5_VEND1 == '"+ _aAux[_nI] +"'" 
		
		If _nI <> Len(_aAux) 
			_cFiltro += " .Or. "
		EndIf
		
	Next _nI
	
 	_cFiltro += " )"

EndIf         
               
//====================================================================================================
// Por coordenador
//====================================================================================================
If !Empty(MV_PAR04)
    
    If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf
	
	_aAux := StrTokArr( AllTrim(MV_PAR04) , ";" )
	
	For _nI := 1 to Len(_aAux)
		
		_cFiltro += "C5_VEND2 == '"+ _aAux[_nI] +"'" 
		
		If _nI <> Len(_aAux)
			_cFiltro += " .Or. "
		EndIf
		
	Next _nI
	
 	_cFiltro += " )"

EndIf

//====================================================================================================
// Por supervisor
//====================================================================================================
If !Empty(MV_PAR16)
    
    If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf
	
	_aAux := StrTokArr( AllTrim(MV_PAR16) , ";" )
	
	For _nI := 1 to Len(_aAux)
		
		_cFiltro += "C5_VEND4 == '"+ _aAux[_nI] +"'" 
		
		If _nI <> Len(_aAux)
			_cFiltro += " .Or. "
		EndIf
		
	Next _nI
	
 	_cFiltro += " )"

EndIf


//====================================================================================================
// Por rede
//====================================================================================================
If !Empty(MV_PAR05)
    
    If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf
	
	_aAux := StrTokArr( AllTrim(MV_PAR05) , ";" )
	
	For _nI := 1 to Len(_aAux)
		
		_cFiltro += "C5_I_GRPVE == '"+ _aAux[_nI] +"'"
		
		If _nI <> Len(_aAux)
			_cFiltro += " .Or. "
		EndIf
		
	Next _nI
	
 	_cFiltro += " )"

EndIf                    

//====================================================================================================
// Por cliente
//====================================================================================================
If !Empty(MV_PAR06)
    
    If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf
    
    _cFiltro += " C5_CLIENTE == '"+ MV_PAR06 +"'"
    _cFiltro += " )"

EndIf 

//====================================================================================================
// Por Status do pedido - Fixado para trazer só pedidos sem nota e sem liberação
//====================================================================================================
If Empty(_cFiltro)
   	_cFiltro += " ( "
Else
	_cFiltro += " .And. ( "
EndIf
		
_cFiltro += " Empty(C5_LIBEROK) .And. Empty(C5_NOTA) .And. Empty(C5_BLQ) "
_cFiltro += " ) "

//====================================================================================================
// Filtros de tipos de agenda
//====================================================================================================
If !Empty(MV_PAR17)
    
    If Empty(_cFiltro)
    	_cFiltro += " ( "
	Else
        _cFiltro += " .And. ( "
    EndIf
	
	_aAux := StrTokArr( AllTrim(MV_PAR17) , ";" )
	
	For _nI := 1 to Len(_aAux)
		
		_cFiltro += "C5_I_AGEND == '"+ _aAux[_nI] +"'"
		
		If _nI <> Len(_aAux)
			_cFiltro += " .Or. "
		EndIf
		
	Next _nI
	
 	_cFiltro += " )"

EndIf        

//====================================================================================================
// Filtra por pedido
//====================================================================================================
If (!Empty(MV_PAR12) .Or. !Empty(MV_PAR13)) .And. _lresp

   If Empty(_cFiltro)
      _cFiltro += " ( "
   Else
      _cFiltro += " .And. ( "
   EndIf 
	
   If !Empty(MV_PAR12)
	  _cFiltro += " C5_NUM >= '"+MV_PAR12+"' "
   EndIf

   If !Empty(MV_PAR13) 
       
      If !Empty(MV_PAR12)
         _cFiltro += " .And. "
      EndIf

      _cFiltro += " C5_NUM <= '"+MV_PAR13+"' "

   EndIf

   _cFiltro += " ) "

EndIf

//====================================================================================================
// Não libera pedido de venda do tipo bonificacao que esteja com o status bloqueado ou rejeitado
//====================================================================================================
If !Empty(_cFiltro)
   	_cFiltro += " .And. "
EndIf

_cFiltro += " (C5_I_BLOQ <> 'B' .And. C5_I_BLOQ <> 'R') "

//====================================================================================================
// Filtro  para que nao seja possivel efetuar a liberacao
// de um pedido de venda com Bloqueio de Preço de Venda ou bloqueio de crédito
//====================================================================================================
If !Empty(_cFiltro)
   	_cFiltro += " .And. "
EndIf

_cFiltro+= " (C5_I_BLPRC <> 'B' .And. C5_I_BLPRC <> 'R' .And. C5_I_BLCRE <> 'B' .And. C5_I_BLCRE <> 'R') "


Return( _cFiltro )

/*
===============================================================================================================================
Programa----------: M440LC
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/09/2018
Descrição---------: Valida armazém do pedido de vendas
Parametros--------: _cLocal - String com armazéns válidos
Retorno-----------: _cret - lógico indicando validação ou não
===============================================================================================================================
*/
User Function M440LC(_clocal)
Local _cret := .T.

SC6->(DBSetOrder(1))
If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

	While SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->C5_NUM == SC6->C6_NUM

		If !(AllTrim(SC6->C6_LOCAL) $ _clocal)
	
			_cret := .F.
			Exit
		
		EndIf
		
	EndDo
	
EndIf
	
Return _cret
