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
Programa----------: MODEL_ABA
Autor-------------: Igor melgaço
Data da Criacao---: 24/07/2025
Descrição---------: Pontos de entradas do FISA001 Chamado:51556
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MODEL_ABA()

   Local aParam := ParamIXB

   If aParam <> NIL
      //oObj    := aParam[1]
      cIdPonto  := aParam[2]
      //cIdModel:= aParam[3]
      //lIsGrid := (Len(aParam) > 3)

      If     cIdPonto == "MODELPOS" //"Chamada na validação total do modelo."
      ElseIf cIdPonto == "FORMPOS" //"Chamada na validação total do formulário."
      ElseIf cIdPonto == "FORMLINEPRE"//Chamada na pré validação da linha do formulário
      ElseIf cIdPonto == "FORMLINEPOS"//Chamada na validação da linha do formulário
      ElseIf cIdPonto == "MODELCOMMITTTS"//Chamada após a gravação total do modelo e dentro da transação.
      ElseIf cIdPonto == "MODELCOMMITNTTS"//Chamada após a gravação total do modelo e fora da transação.
      ElseIf cIdPonto == "FORMCOMMITTTSPRE"//Chamada após a gravação da tabela do formulário.
      ElseIf cIdPonto == "FORMCOMMITTTSPOS"//Chamada após a gravação da tabela do formulário.
      ElseIf cIdPonto == "MODELCANCEL"
      ElseIf cIdPonto == "BUTTONBAR"
         aRet := {}
         aAdd( aRet ,{"Relatório de Conferência EFD" , 'Relatório de Conferência EFD' , {|| FSA001REL() } , "Relatório de Conferência EFD" } )
         Return aRet
      EndIf

   EndIf

Return .T.
