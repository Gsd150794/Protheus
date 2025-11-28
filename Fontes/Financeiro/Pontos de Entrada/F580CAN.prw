/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |22/10/2019| Chamado 30921. Tratamento para o campo NOVO CLAIM.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F580CAN
Autor-------------: Alex Wallauer 
Data da Criacao---: 22/10/2019 
Descrição---------: PE de validação do calcelamento da liberação manual de baixa de titulo a pagar
Parametros--------: Nenhum
Retorno-----------: Lógico - Indicando se os dados foram validados ou não
===============================================================================================================================
*/
User Function F580CAN()

If SE2->E2_I_CLAIM = "2"

    _lAcesso := U_ITVACESS( 'ZZL' , 3 , 'ZZL_CLAIM' , "S" )

    If !_lAcesso

	    U_ITMsg('Usuário sem permissão para cancelar a liberação de titulos com Claim = Sim',"ATENÇÃO",;
		   	    'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.', 1  )
        Return .F.

    EndIf


   SE2->(RecLock("SE2",.F.))
   SE2->E2_I_CLAIM:= "1"
   SE2->(MSUnLock())


EndIf

Return .T.
