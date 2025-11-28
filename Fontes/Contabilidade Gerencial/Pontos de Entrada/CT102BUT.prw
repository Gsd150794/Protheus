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
Programa----------: CT102BUT
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 11/02/2019
Descrição---------: Ponto de Entrada que permite adicionar novos botões para o array aRotina, no menu da mbrowse em lançamentos 
					contábeis automáticos.
Parametros--------: aRotina
Retorno-----------: aRotina
===============================================================================================================================
*/
User Function CT102BUT

Local aRotina := {}

aAdd(aRotina,{"Consulta LOG","U_CCTBLGA()",0,2,0,nil})
	
Return (aRotina)

/*
===============================================================================================================================
Programa----------: CCTBLGA
Autor-------------: Alexandre Villar
Data da Criacao---: 24/02/2014
Descrição---------: Consulta dos campos de Log de Inclusão/Alteração da tabela CT2
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CCTBLGA()

Local _aCabec	:= { 'Operação' , 'Tabela' , 'Usuário' , 'Data' }
Local _aDados	:= {}
Local _cAlias	:= ''
Local _lDados	:= .F.
Local _nI		:= 0

_cAlias := 'CT2'

aAdd( _aDados , { 'Inclusão'	, _cAlias , FWLeUserlg( _cAlias +"_USERGI" , 1 ) , FWLeUserlg( _cAlias +"_USERGI" , 2 ) } )
aAdd( _aDados , { 'Alteração'	, _cAlias , FWLeUserlg( _cAlias +"_USERGA" , 1 ) , FWLeUserlg( _cAlias +"_USERGA" , 2 ) } )

For _nI := 1 To Len( _aDados )
	
	If !Empty( _aDados[_nI][03] )
		
		_lDados := .T.
		Exit
		
	EndIf
	
Next _nI

If _lDados
	U_ITListBox( 'Log de Alterações - Lançamentos Contábeis:' , _aCabec , _aDados , .F. , 1 , 'Dados das últimas alterações (se existirem)' )
Else
	Aviso( 'Atenção!' , 'Não existem registros de LOG para o lançamento selecionado! Verifique os dados e tente novamente.' , {'Voltar'} , 2 )
EndIf

Return
