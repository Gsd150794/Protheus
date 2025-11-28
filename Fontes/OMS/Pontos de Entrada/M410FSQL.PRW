/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |08/08/2019| Chamado 29634. Inclusão de novo filtro para a nova rotina de monitoramento (Gestão de Carteira).
Julio Paz     |02/04/2020| Chamado 31241. Inclusão de novo filtro para pedidos de vendas rejeitados.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

/*
===============================================================================================================================
Programa----------: M410FSQL
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/04/2018
Descrição---------: PE para filtrar registros na tela de pedidos de venda - Chamado 8543
Parametros--------: Nenhum
Retorno-----------: cFilSQL(caracter) Expressão SQL utilizada para filtrar a mBrowse.
===============================================================================================================================
*/
User Function M410FSQL()
 
Local _cPerg	:= "M410FSQL"
Local _cFiltro	:= ""//" .T. "
Local _aAux		:= {}
Local _nI		:= 0
Local _lresp    := .F.
Local _lexec    := u_itgetmv("ITFILPV",.F.)

Begin Sequence 
   If IsInCallStack("U_AOMS097L")
      _cFiltro += "(C5_FILIAL == '" + _cCodFilial + "' .And. C5_NUM == '" + _cNrPedido + "' ) " 
      
	  Break
   EndIf

   If _lexec

	  _lresp := Pergunte( _cPerg , .T. )
	
   EndIf

   If !_lresp

	   MV_PAR01:=MV_PAR02:=MV_PAR03:=MV_PAR04:=MV_PAR05:=Space(100)
      MV_PAR06:=Space(6)
      MV_PAR07:=1
	
      Break // Cancela o filtro, caso o pergunte seja cancelado.

   EndIf

   //====================================================================================================
   //Adiciona filial  para melhorar a performance
   //====================================================================================================
   If Empty(_cFiltro)
      _cFiltro += " ( "
   Else
      _cFiltro += " .And. ( "
   EndIf 
   
   _cFiltro += "  C5_FILIAL == '" + cfilant + "')"
	
   //====================================================================================================
   //Filtra status de pedido
   //====================================================================================================
   If MV_PAR07 = 2

	  If Empty(_cFiltro)
    	 _cFiltro += " ( "
      Else
         _cFiltro += " .And. ( "
      EndIf 
   
      _cFiltro += "  C5_NOTA > ' ')"
    
   ElseIf MV_PAR07 = 3

	  If Empty(_cFiltro)
    	 _cFiltro += " ( "
      Else
         _cFiltro += " .And. ( "
      EndIf 
   
      _cFiltro += "  !(C5_NOTA > ' ') )"
      
   EndIf

   //====================================================================================================
   // Filtra Tipos de Bloqueios
   //====================================================================================================
   If MV_PAR08 = 2 // 'Com Bloqueio de Preço'

	  If Empty(_cFiltro)
    	 _cFiltro += " ( "
      Else
         _cFiltro += " .And. ( "
      EndIf 
    
      _cFiltro += "  C5_I_BLPRC = 'B' )"
    
   ElseIf MV_PAR08 = 3 // 'Com Preço Rejeitado'

	  If Empty(_cFiltro)
    	 _cFiltro += " ( "
      Else
         _cFiltro += " .And. ( "
      EndIf 
   
      _cFiltro += "  C5_I_BLPRC = 'R' )"

   ElseIf MV_PAR08 = 4  // 'Com Bloqueio de Credito'

	  If Empty(_cFiltro)
    	 _cFiltro += " ( "
      Else
         _cFiltro += " .And. ( "
      EndIf 
    
      _cFiltro += "  C5_I_BLCRE = 'B' )"

   ElseIf MV_PAR08 = 5  // 'Com Credito Rejeitado'  

	   If Empty(_cFiltro)
    	 _cFiltro += " ( "
      Else
         _cFiltro += " .And. ( "
      EndIf 
  
      _cFiltro += "  C5_I_BLCRE = 'R' )"

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
   // Por supervisor
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

End Sequence

Return( _cFiltro )
