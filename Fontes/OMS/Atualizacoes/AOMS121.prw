/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
                  |            | 
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AOMS121
Autor-----------: Julio de Paula Paz
Data da Criacao-: 22/02/2021
===============================================================================================================================
Descrição-------: Cadastro de taxas de seguro para fretes por filial e Transportadora.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS121()

Local _cVldAlt
Local _cVldExc

Begin Sequence 
   DBSelectArea("ZGX")
   ZGX->(DBSetOrder(1))
   
   _cVldAlt := "U_AOMS121V()" // Validacao para permitir a inclusao. Pode-se utilizar ExecBlock.
   _cVldExc := ".T."          // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.


   //AxCadastro("SA1", "Clientes", "U_DelOk()", "U_COK()", aRotAdic, bPre, bOK, bTTS, bNoTTS, , , aButtons, , )
   AxCadastro("ZGX","Cadastro de Percentual de Seguro Para Frete por Filial e Transportadora",_cVldExc,_cVldAlt)

End Sequence

Return 

/*
===============================================================================================================================
Programa--------: AOMS121V
Autor-----------: Julio de Paula Paz
Data da Criacao-: 22/02/2021
===============================================================================================================================
Descrição-------: Valida a gravação da inclusão e da alteração.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS121V()  
Local _lRet   := .T.

Begin Sequence 

   If Inclui
      If Empty(M->ZGX_FILSEG)
         U_ITMsg("O Preenchimento da filial do percentual de seguro do frete é obrigatório.",1,"Atenção") 
         _lRet :=.F.
         Break
      EndIf

      If Empty(M->ZGX_TRANSP)
         U_ITMsg("O Preenchimento do código da transportadoras do percentual de seguro  do frete é obrigatório.",1,"Atenção") 
         _lRet :=.F.
         Break 
      EndIf 

      If Empty(M->ZGX_LOJATR)
         U_ITMsg("O Preenchimento da loja da transportadora do percentual de seguro do frete é obrigatório.",1,"Atenção") 
         _lRet :=.F.
         Break
      EndIf 

      If Empty(M->ZGX_PERSEG)
         U_ITMsg("O Preenchimento do percentual de seguro do frete é obrigatório.",1,"Atenção") 
         _lRet :=.F.
         Break
      EndIf 

      ZGX->(DBSetOrder(1))
      If ZGX->(MsSeek(xFilial("ZGX")+M->ZGX_FILSEG+M->ZGX_TRANSP+M->ZGX_LOJATR))
         U_ITMsg("Já existe percentual de seguro cadastrado para esta filial, transportadora e loja!",1,"Atenção") 
         _lRet :=.F.
         Break
      EndIf

   ElseIf Altera 
      If Empty(M->ZGX_FILSEG)
         U_ITMsg("O Preenchimento da filial do percentual de seguro do frete é obrigatório.",1,"Atenção") 
         _lRet :=.F.
         Break
      EndIf

      If Empty(M->ZGX_TRANSP)
         U_ITMsg("O Preenchimento do código da transportadoras do percentual de seguro  do frete é obrigatório.",1,"Atenção") 
         _lRet :=.F.
         Break 
      EndIf 

      If Empty(M->ZGX_LOJATR)
         U_ITMsg("O Preenchimento da loja da transportadora do percentual de seguro do frete é obrigatório.",1,"Atenção") 
         _lRet :=.F.
         Break
      EndIf 

      If Empty(M->ZGX_PERSEG)
         U_ITMsg("O Preenchimento do percentual de seguro do frete é obrigatório.",1,"Atenção") 
         _lRet :=.F.
         Break
      EndIf 

      If ZGX->ZGX_FILSEG <> M->ZGX_FILSEG .Or. ZGX->ZGX_TRANSP <> M->ZGX_TRANSP .Or. ZGX->ZGX_LOJATR <> M->ZGX_LOJATR
         U_ITMsg("Não é permitido alterar a filial do percentual de seguro, a Transportadora e a Loja.",1,"Atenção") 
         _lRet :=.F.
         Break
      EndIf
   
   EndIf
	
End Sequence

Return _lRet
