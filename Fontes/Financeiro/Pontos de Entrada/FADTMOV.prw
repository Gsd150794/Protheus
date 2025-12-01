/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Analista      - Programador  - Inicio   - Envio    - Chamado - Motivo da Alteração                                                                                 
============================================================================================================================================================== 
Antonio Ramos  - Julio Paz    - 07/08/25 - 12/08/25 -  51685  - Criação de Nova validação na digitação da data de baixa de Títulos de Contas a Pagar.        
Antonio Ramos  - Julio Paz    - 04/11/25 - 28/11/25 -  52481  - Criação de Nova validação na digitação da data de baixa de Títulos de Contas a Receber.        
============================================================================================================================================================== 
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
Local _aParam := PARAMIXB
Local _dData 
Local _nDiasAvan
Local _cCampo	:= ReadVar()

Begin Sequence 

   If (FWIsInCallStack("FA090AUT") .Or. FWIsInCallStack("FA330COMP")) .And. _cCampo == "DBAIXA"
      PswOrder(1)
      PswSeek(__cUserId,.T.)
      _aUsuario := PswRet()
   
      _nDiasAvan := _aUsuario[1,23,3] // Numero de dias que o usuário pode avançar a data base do Protheus, ao fazer login no Protheus.

      _dData := _aParam[1] // Data da baixa informado na tela pelo usuário.

      If Dtos(_dData) > Dtos(Date() + _nDiasAvan)
         U_ItMsg("Usuário sem permissão de informar uma data de baixa superior a: " + Dtoc(Date() + _nDiasAvan) + ". ","Atenção",,1)
         _lRet := .F.
      EndIf 
      
      If Dtos(_dData) < Dtos(Date() - _nDiasAvan)
         U_ItMsg("Usuário sem permissão de informar uma data de baixa inferior a: " + Dtoc(Date() - _nDiasAvan) + ". ","Atenção",,1)
         _lRet := .F.
      EndIf 
   EndIf

End Sequence 

Return _lRet 
