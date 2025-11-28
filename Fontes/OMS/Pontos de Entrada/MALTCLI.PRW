/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 03/04/2018 | Chamado 24395. Incluída na regra da Conta Contábil o tipo L-Produtor Rural pois está sendo usado. 
Alex Wallauer | 17/02/2023 | Chamado 42425. Novo Tratamento para gravacao do campo A1_CONTRIB na nova Funcao CRMA980CON().
======================================================================================================================================================================================================
 Analista     - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
======================================================================================================================================================================================================
 Antonio      - Igor Melgaço  - 11/11/25 -           - 51346   - Ajuste para replicar A1_COND e A1_GRPVEN entre clientes com mesma base de CNPJ.
======================================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "rwmake.ch" 
#Include "TOPCONN.CH"       

/*
===============================================================================================================================
Programa--------: MALTCLI
Autor-----------: Alexandre Villar
Data da Criacao-: 17/06/2014
===============================================================================================================================
Descrição-------: Ponto de entrada para gravar os dados do cadastro do Cliente após a alteração.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MALTCLI()

Local _aArea	:= FWGetArea()
Local _cCodUsr	:= RetCodUsr()
Local _cConta	:= ''

//================================================================================
//| Verifica se o LOG de Alterações está ativo e chama a ggravação do LOG        |
//================================================================================
If Type("_aITASA1") == "A" .And. !Empty(_aITASA1)
	U_ITGrvLog( _aITASA1 , "SA1" , 1 , SA1->( A1_FILIAL + A1_COD + A1_LOJA ) , "A" , _cCodUsr )
EndIf

_aITASA1 := {}

FWRestArea( _aArea )

//====================================================================================================
// Verifica a configuração do cadastro para ajustar a conta contábil
//====================================================================================================
Do Case
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'AM' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069992'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'RS' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069993'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'MG' .And. SA1->A1_PESSOA == 'F' .And. SA1->A1_COD_MUN == '69307' //Três Corações
		_cConta := '1102069995'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'SP' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069996'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST $ 'MG/GO' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069998'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'RO' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069999'
	
EndCase

If !Empty( _cConta ) .And. _cConta <> SA1->A1_CONTA
	
	RecLock( 'SA1' , .F. )
	SA1->A1_CONTA := _cConta
	SA1->( MSUnLock() )
	
EndIf

U_CRMA980CON()//Funcao do P.E. CRMA980PE.PRW

U_CRMA980A(M->A1_COND,M->A1_GRPVEN,M->A1_I_NGRPC) // Ajuste para replicar A1_COND e A1_GRPVEN entre clientes com mesma base de CNPJ. Chamado 51346.

Return
