/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |12/08/2025| Chamado 51685. Criação de Nova validação na digitação da data de baixa de Títulos de Contas a Pagar.        
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Função-------------: FADTMOV
Autor--------------: Julio de Paula Paz
Data da Criacao----: 29/08/2024 
Descrição----------: Ponto de entrada na validação da Data da Baixa da tela Baixa Automática de Contas a Pagar.
Parametros---------: {dDatabaixa} = data da baixa informada na tela.
Retorno------------: _lRet = .T. = Data OK.
                             .F. = Data inválida.
===============================================================================================================================
*/  
User Function FADTMOV()
Local _lRet := .T.
Local _aUsuario 
Local _aParam := ParamIXB
Local _dData 
Local _nDiasAvan
Local _cCampo	:= ReadVar()

Begin Sequence 
   
   If FWIsInCallStack("FA090AUT") .And. _cCampo == "DBAIXA"
      PswOrder(1)
      PswSeek(__cUserId,.T.)
      _aUsuario := PswRet()
   
      _nDiasAvan := _aUsuario[1,23,3] // Numero de dias que o usuário pode avançar a data base do Protheus, ao fazer login no Protheus.

      _dData := _aParam[1] // Data da baixa informado na tela pelo usuário.

      If DToS(_dData) > DToS(Date() + _nDiasAvan)
         U_ITMsg("Usuário sem permissão de informar uma data de baixa superior a: " + DToC(Date() + _nDiasAvan) + ". ","Atenção",,1)
         _lRet := .F.
      EndIf 
      
   EndIf

End Sequence 

Return _lRet 
