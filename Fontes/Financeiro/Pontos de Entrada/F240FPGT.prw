/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/08/2019| Chamado 30185. Modificada validação de acesso aos setores.
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Wallauer |03/11/2021| Chamado 38128. Novo Filtro Geral E2_MSBLQL <> '1'.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F240FPGT
Autor-------------: Alex Wallauer
Data da Criacao---: 24/03/2017
Descrição---------: P.E. - Na montagem de borderô de títulos a pagar 
Retorno-----------: _cQuery - Filtro a ser realizado
===============================================================================================================================
*/
User Function F240FPGT()

Local _cQueSA2	:= ''
Local _aArea	:= FWGetArea()
Local _aParam	:= {}
Local _cPerg	:= 'F240FI2'
Local _cQuery	:= ''
Local _lAplFil	:= .F.
Local _nVlrTed	:= GetMV( "IT_VLRTED" ,, 2000 ) // Parametro contendo o Valor do DOC/TED 

//====================================================================================================
// Guarda parametros padrão da rotina
//====================================================================================================
Local _cPar01 := MV_PAR01
Local _cPar02 := MV_PAR02
Local _cPar03 := MV_PAR03
Local _cPar04 := MV_PAR04
Local _cPar05 := MV_PAR05
Local _cPar06 := MV_PAR06
Local _cPar07 := MV_PAR07
Local _cPar08 := MV_PAR08
Local _cPar09 := MV_PAR09
Local _cPar10 := MV_PAR10
Local _cPar11 := MV_PAR11
Local _cPar12 := MV_PAR12
Local _cPar14 := MV_PAR14
Local _cPar15 := MV_PAR15
Local _cPar16 := MV_PAR16

//Grava log de uso
u_itlogacs()

//====================================================================================================
// Verifica se Processa os paramatros para o filtro
//====================================================================================================
If U_ITMsg( "Aplicar Filtro complementar da Gestao do Leite?","F240FPGT001",,3,2,2)
	
	If Pergunte( _cPerg )
		
		_lAplFil := .T.
		
		aAdd( _aParam , MV_PAR01 )	// 01 - Cod. Fornecedor Inicial
		aAdd( _aParam , MV_PAR03 )	// 02 - Cod. Fornecedor Final
		aAdd( _aParam , MV_PAR02 )	// 03 - Loja Fornecedor Inicial
		aAdd( _aParam , MV_PAR04 )	// 04 - Loja Fornecedor Final
		aAdd( _aParam , MV_PAR08 )	// 05 - Código da Linha Inicial
		aAdd( _aParam , MV_PAR09 )	// 06 - Código da Linha Final
		aAdd( _aParam , MV_PAR10 )	// 07 - Código do Banco Inicial
		aAdd( _aParam , MV_PAR11 )	// 08 - Código do Banco Final
		aAdd( _aParam , MV_PAR12 )	// 09 - Código da Agência
		aAdd( _aParam , MV_PAR13 )	// 10 - Código do Mix
		aAdd( _aParam , MV_PAR14 )	// 11 - Cód. do Fornecedor Associado
		aAdd( _aParam , MV_PAR15 )	// 12 - Loja do Fornecedor Associado
		
		Do Case						// 13 - Cód. do Tipo de Pagamento
			Case MV_PAR05 == 1
				aAdd( _aParam , "T" ) // Todas
			Case MV_PAR05 == 2
				aAdd( _aParam , "B" ) // Banco
			Case MV_PAR05 == 3
				aAdd( _aParam , "C" ) // Cheque
			Case MV_PAR05 == 4
				aAdd( _aParam , "D" ) // Dinheiro
		EndCase
		
		If MV_PAR06 == 1			// 14 - Código do Setor
			aAdd( _aParam , MV_PAR07 ) 
		Else
			aAdd( _aParam , ''       )
		EndIf
		
		aAdd( _aParam , MV_PAR16 )	// 15 - Filiais
		
	EndIf

EndIf

If _lAplFil

   If !Empty(_aParam[02])//TESTE - OK
	  _cQuery += " E2_FORNECE BETWEEN '"+ _aParam[01]			+"' AND '"+ _aParam[02]			+"' AND "
   EndIf
   If !Empty(_aParam[04])//TESTE - OK
	  _cQuery += " E2_LOJA    BETWEEN '"+ _aParam[03]			+"' AND '"+ _aParam[04]			+"' AND "
   EndIf
   If !Empty(_aParam[08])//TESTE - OK
	  _cQuery += " E2_L_BANCO BETWEEN '"+ _aParam[07]			+"' AND '"+ _aParam[08]			+"' AND "
   EndIf
   If !Empty(_aParam[06])//TESTE - OK
	  _cQuery += " E2_L_LINRO BETWEEN '"+ _aParam[05]			+"' AND '"+ _aParam[06]			+"' AND "
   EndIf

    _cQuery += " SubStr( E2_FORNECE , 1 , 1 ) IN ('P','G') AND "//TESTE - OK
	
	If !Empty( _aParam[10] )//TESTE - OK
	   _cQuery += " E2_L_MIX   = '"+ _aParam[10] +"' AND "
	EndIf
	
	If !Empty( _aParam[14] )//TESTE - OK
	   _cQuery += " E2_L_SETOR = '"+ _aParam[14] +"' AND "
	EndIf
	
	If _aParam[13] == "B" .And. !Empty( _aParam[09] )//TESTE - OK
	   _cQuery += " E2_L_AGENC = '"+ _aParam[09] +"' AND "
	EndIf

EndIf

If U_ITMsg( "Aplicar Filtro do CNAB?","F240FPGT002",,3,2,2 )
	
   Do Case

	Case cModPgto == '01' // Crédito em conta corrente //TESTE - OK
	
		_cQuery  += " E2_CODBAR = ' ' AND "

		_cQueSA2 += " AND SA2.A2_BANCO  = '"+ cPort240 +"' "
	
	Case cModPgto == '03' // DOC/TED para Banco do Brasil e BMB - DOC para outros
	
		If cPort240 == "001" .Or. cPort240 == "389" // Banco do Brasil ou Mercantil//TESTE - OK
			_cQuery  += " E2_CODBAR = ' ' AND "

			_cQueSA2 += " AND NOT SA2.A2_BANCO = '"+ cPort240 +"' "
		Else//TESTE - OK
			_cQuery  += " E2_CODBAR = ' ' AND E2_SALDO + E2_SDACRES - E2_SDDECRE < "+ cValToChar(_nVlrTed)+" AND "

			_cQueSA2 += " AND NOT SA2.A2_BANCO = '"+ cPort240 +"' "
		EndIf
	
	Case cModPgto == '08' // TED - Banco Bradesco//TESTE - OK
		
		_cQuery  += " E2_CODBAR = ' ' AND E2_SALDO + E2_SDACRES - E2_SDDECRE >= "+ cValToChar(_nVlrTed)+" AND "

		_cQueSA2 += " AND NOT SA2.A2_BANCO = '"+ cPort240 +"' "
	
	Case cModPgto $ '30-31' .And. cPort240 == '389' // Título próprio ou outros bancos no Banco Mercantil//conta bloqueada
	
		_cQuery  += " NOT E2_CODBAR = ' ' AND "

 	Case cModPgto == '30' // Título próprio do Banco//TESTE - OK
 	
 		_cQuery  += " SubStr( E2_CODBAR , 1 , 3 ) = '"+ cPort240 +"' AND "
	
	Case cModPgto == '31' // Títulos de outros bancos//TESTE - OK
		
		_cQuery  += " NOT SubStr( E2_CODBAR , 1 , 3 ) = '"+ cPort240 +"' AND "
	
	Case cModPgto == '41' .And. cPort240 == '341' // TED - Banco Itau//TESTE - OK
	
		_cQuery  += " E2_CODBAR = ' ' AND E2_SALDO + E2_SDACRES - E2_SDDECRE >= "+ cValToChar(_nVlrTed)+" AND "

		_cQueSA2 += " AND NOT SA2.A2_BANCO = '"+ cPort240 +"' "

   EndCase

EndIf

If !Empty(_cQueSA2) .Or. (_lAplFil .And. (_aParam[13] <> "T" .Or. !Empty( _aParam[11])) )//TESTE - OK

   _cQuery += "     EXISTS (SELECT SA2.A2_COD "
   _cQuery += "             FROM  "+ RETSQLNAME("SA2") +" SA2 "
   _cQuery += "             WHERE "+ RETSQLCOND('SA2')
   _cQuery += "             AND SA2.A2_COD  = E2_FORNECE "
   _cQuery += "             AND SA2.A2_LOJA = E2_LOJA "

   If !Empty(_aParam) .And. _aParam[13] <> "T"//TESTE - OK
      _cQuery += "          AND SA2.A2_L_TPPAG = '"+ _aParam[13] +"' "
   EndIf

   If !Empty(_aParam) .And. !Empty( _aParam[11] )
      _cQuery += "          AND SA2.A2_L_FORTX  = '"+ _aParam[11] +"' "
      If !Empty( _aParam[12] )
         _cQuery += "       AND SA2.A2_L_LOJTX  = '"+ _aParam[12] +"' "
      EndIf
   EndIf

   _cQuery += _cQueSA2 +" ) AND "

EndIf

//====================================================================================================
// Aplica filtro Títulos Impostos 
//====================================================================================================
If U_ITMsg( "Aplicar Filtro de Impostos?","Atenção",,3,2,2 )

   _cQuery += " E2_TIPO = 'TX' AND "
	
EndIf

_cQuery += " E2_MSBLQL <> '1' AND "

//====================================================================================================
// Restaura parametros (padrao da rotina)
//====================================================================================================
MV_PAR01 := _cPar01
MV_PAR02 := _cPar02
MV_PAR03 := _cPar03
MV_PAR04 := _cPar04
MV_PAR05 := _cPar05
MV_PAR06 := _cPar06
MV_PAR07 := _cPar07
MV_PAR08 := _cPar08
MV_PAR09 := _cPar09
MV_PAR10 := _cPar10
MV_PAR11 := _cPar11
MV_PAR12 := _cPar12
MV_PAR14 := _cPar14
MV_PAR15 := _cPar15
MV_PAR16 := _cPar16

FWRestArea(_aArea)

Return _cQuery
