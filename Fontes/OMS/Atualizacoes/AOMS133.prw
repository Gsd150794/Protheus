/*
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                              Motivo                                                          |
-------------------------------------------------------------------------------------------------------------------------------
                  |            | 
=============================================================================================================================== 
*/
#Include "TOTVS.ch"
/*
===============================================================================================================================
Programa----------: AOMS133
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/06/2022
===============================================================================================================================
Descrição---------: Rotina de manutenção no cadastro de Descontos Fretes por Toneladas para Pedidos Fob. Chamado 40365.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum 
===============================================================================================================================
*/  
User Function AOMS133()
Local _cTitulo := "Cadastro de Descontos de Frete por Toneladas para Pedidos Fob."

Begin Sequence
   AxCadastro("ZBL",_cTitulo)
End Sequence

Return       

/*
===============================================================================================================================
Programa----------: AOMS133V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/06/2022
===============================================================================================================================
Descrição---------: Validar a digitação dos dados no cadastro de Descontos Fretes por Toneladas para Pedidos Fob.
===============================================================================================================================
Uso---------------: Italac
===============================================================================================================================
Parametros--------: _cCampo = Campo ou trecho da rotina que chamou a validação.
===============================================================================================================================
Retorno-----------: True ou False
===============================================================================================================================
*/  
User Function AOMS133V(_cCampo) 
Local _lRet := .T.   
//Local _aFilial
//Local _nI

Begin Sequence
   If _cCampo == "ZBL_CODFIL" 
/*     
      _aFilial := FwLoadSM0() 

      _nI := aScan(_aFilial,{|x| x[5] = M->ZBL_CODFIL})   
      
      If _nI == 0
         MsgInfo("O código de filial informado não existe.","Atenção")
         _lRet := .F.
         Break
      Else
         M->ZG9_NOME := _aFilial[_nI,7]
      EndIf
      */

   ElseIf _cCampo == "ZBL_CODMUN" 
      
      //U_AOMS133V("ZBL_CODMUN")

      M->ZBL_MUN := Posicione("CC2",1,xFilial("CC2")+M->ZBL_UF+M->ZBL_CODMUN,"CC2_MUN") // CC2_FILIAL+CC2_EST+CC2_CODMUN

   ElseIf _cCampo == "ZBL_MESO"
      //4 = Z21_FILIAL+Z21_EST+Z21_COD 
      //1 = Z21_FILIAL+Z21_COD 
      
      //U_AOMS133V("ZBL_MESO")

      //M->ZBL_NMESO := Posicione("Z21",4,xFilial("Z21")+M->ZBL_UF+M->ZBL_MESO,"Z21_NOME")
      If Empty( M->ZBL_MESO)
         M->ZBL_NMESO := Space(30)
      Else 
         If ! ExistCpo("Z21",M->ZBL_UF+M->ZBL_MESO,4)
            _lRet := .F. 
         Else
            M->ZBL_NMESO := Posicione("Z21",1,xFilial("Z21") + M->ZBL_MESO,"Z21_NOME")
         EndIf 
      EndIf 

   ElseIf _cCampo == "ZBL_MICRO"
      // 1 = Z22_FILIAL+Z22_COD 
      // 4 = Z22_FILIAL+Z22_EST+Z22_MESO+Z22_COD

     //U_AOMS133V("ZBL_MICRO")

     //M->ZBL_NMICRO := Posicione("Z22",4,xFilial("Z22")+M->ZBL_UF+M->ZBL_MICRO,"Z22_NOME")
     If Empty(M->ZBL_MICRO)
        M->ZBL_NMICRO := Space(30)
     Else 
        If ! ExistCpo("Z22",M->ZBL_MICRO,1)
           _lRet := .F. 
        Else 
           M->ZBL_NMICRO := Posicione("Z22",1,xFilial("Z22")+M->ZBL_MICRO,"Z22_NOME")
        EndIf 
     EndIf 
   EndIf
   
End Sequence

Return _lRet


