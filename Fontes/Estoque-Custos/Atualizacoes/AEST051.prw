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
Programa----------: AEST051
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/05/2024
Descrição---------: Rotina de manutenção no Cadastro de Origem e Destino de Transferência de Produtos. Chamado 46556.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AEST051()

Local _cVldAlt
Local _cVldExc

Begin Sequence 
   DBSelectArea("ZCF")
   ZCF->(DBSetOrder(1))
   
   _cVldAlt := "U_AEST051V('BOK')" // Validacao para permitir a inclusao. Pode-se utilizar ExecBlock.
   _cVldExc := ".T."          // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.

   //AxCadastro("SA1", "Clientes", "U_DelOk()", "U_COK()", aRotAdic, bPre, bOK, bTTS, bNoTTS, , , aButtons, , )
   AxCadastro("ZCF","Cadastro de Origem e Destino para Transferência de Produtos",_cVldExc,_cVldAlt)

End Sequence

Return 

/*
===============================================================================================================================
Programa--------: AEST051V
Autor-----------: Julio de Paula Paz
Data da Criacao-: 20/05/2024
Descrição-------: Valida a gravação da inclusão e da alteração.
Parametros------: _cCampo = Campo que chamou a validação.
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AEST051V(_cCampo)  
Local _lRet   := .T.

Begin Sequence 
   If _cCampo == "BOK"
      If Inclui
         If Empty(M->ZCF_CODIGO)
            U_ITMsg("O Preenchimento do codigo de Origem/Destino é obrigatório.","Atenção",,1) 
            _lRet :=.F.
            Break
         Else 
            ZCF->(DBSetOrder(1))
            If ZCF->(MsSeek(xFilial("ZCF")+M->ZCF_CODIGO))
               U_ITMsg("Já existe uma Origem/Destino com este código.","Atenção",,1) 
               _lRet :=.F.
               Break
            EndIf 
         EndIf

         If Empty(M->ZCF_ORIGDE)
            U_ITMsg("O Preenchimento da descrição do Código de Origem/Destino  é obrigatório.","Atenção",,1) 
            _lRet :=.F.
            Break 
         EndIf 

         If Empty(M->ZCF_MOTTRA)
            U_ITMsg("O Preenchimento do Tipo de Transferência é obrigatório.","Atenção",,1) 
            _lRet :=.F.
            Break
         Else 
            CYO->(DBSetOrder(1)) // CYO_FILIAL+CYO_CDRF
            
            If ! CYO->(MsSeek(xFilial('CYO')+M->ZCF_MOTTRA))
               U_ITMsg("O Código do Tipo de Transferência informado não existe.","Atenção",,1) 
               _lRet :=.F.
               Break
            ElseIf Left(M->ZCF_MOTTRA,1) <> "T"
               U_ITMsg("Os Códigos dos Tipos de Transferências devem iniciar com T.","Atenção","O códigos iniciados com T são exclusivos para as transferências de descarte.",1) 
               _lRet :=.F.
               Break  
            EndIf 

         EndIf 

         M->ZCF_DESMOT := CYO->CYO_DSRF 

      ElseIf Altera 
 
         If Empty(M->ZCF_ORIGDE)
            U_ITMsg("O Preenchimento da descrição do Código de Origem/Destino  é obrigatório.","Atenção",,1) 
            _lRet :=.F.
            Break 
         EndIf 

         If Empty(M->ZCF_MOTTRA)
            U_ITMsg("O Preenchimento do Tipo de Transferência é obrigatório.","Atenção",,1) 
            _lRet :=.F.
            Break
         Else 
            
            CYO->(DBSetOrder(1)) // CYO_FILIAL+CYO_CDRF
            If ! CYO->(MsSeek(xFilial('CYO')+M->ZCF_MOTTRA))
               U_ITMsg("O Código do Tipo de Transferência informado não existe.","Atenção",,1) 
               _lRet :=.F.
               Break
            ElseIf Left(M->ZCF_MOTTRA,1) <> "T"
               U_ITMsg("Os Códigos dos Tipos de Transferências devem iniciar com T.","Atenção","O códigos iniciados com T são exclusivos para as transferências de descarte.",1) 
               _lRet :=.F.
               Break  
            EndIf 

         EndIf 

         M->ZCF_DESMOT := CYO->CYO_DSRF 

      EndIf 
   
   ElseIf _cCampo == "ZCF_CODIGO"
      If Inclui
         If Empty(M->ZCF_CODIGO)
            U_ITMsg("O Preenchimento do codigo de Origem/Destino é obrigatório.","Atenção",,1) 
            _lRet :=.F.
            Break
         Else 
            ZCF->(DBSetOrder(1))
            If ZCF->(MsSeek(xFilial("ZCF")+M->ZCF_CODIGO))
               U_ITMsg("Já existe uma Origem/Destino com este código.","Atenção",,1) 
               _lRet :=.F.
               Break
            EndIf 
         EndIf
      EndIf 
    
   ElseIf _cCampo == "ZCF_ORIGDE"

      If Empty(M->ZCF_ORIGDE)
         U_ITMsg("O Preenchimento da descrição do Código de Origem/Destino  é obrigatório.","Atenção",,1) 
         _lRet :=.F.
         Break 
     EndIf 
  
   ElseIf _cCampo == "ZCF_MOTTRA" 
        
     If Empty(M->ZCF_MOTTRA)
        U_ITMsg("O Preenchimento do Tipo de Transferência é obrigatório.","Atenção",,1) 
        _lRet :=.F.
        Break
     Else 
        CYO->(DBSetOrder(1)) // CYO_FILIAL+CYO_CDRF
        If ! CYO->(MsSeek(xFilial('CYO')+M->ZCF_MOTTRA))
           U_ITMsg("O Código do Tipo de Transferência informado não existe.","Atenção",,1) 
           _lRet :=.F.
           Break
        ElseIf Left(M->ZCF_MOTTRA,1) <> "T"
           U_ITMsg("Os Códigos dos Tipos de Transferências devem iniciar com T.","Atenção","O códigos iniciados com T são exclusivos para as transferências de descarte.",1) 
           _lRet :=.F.
           Break  
        EndIf 

     EndIf 

     M->ZCF_DESMOT := CYO->CYO_DSRF 

  EndIf 

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: AEST051N
Autor-----------: Julio de Paula Paz
Data da Criacao-: 20/05/2024
Descrição-------: Valida a gravação da inclusão e da alteração.
Parametros------: _cCampo = Campo que chamou a validação.
Retorno---------: _cNum = Novo numero para o código da tabela ZCF.
===============================================================================================================================
*/
User Function AEST051N()
Local _cQry := ""
Local _aArea  := FWGetArea()
Local _cNum := ""

Begin Sequence 

   _cQry := " SELECT max(ZCF_CODIGO) MAXIMO FROM " + RetSqlName("ZCF") +" ZCF WHERE ZCF.D_E_L_E_T_ = ' ' "
	_cQry += " AND ZCF_FILIAL = '" + xFilial("ZCF") + "'"
	
   If Select("TRBZCF") > 0
	   TRBZCF->(DBCloseArea())
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry) , "TRBZCF" , .T. , .F. )
   
   If !TRBZCF->(Eof())
      _cNumZCF := AllTrim(TRBZCF->MAXIMO)
   EndIf 

   _cNum   := GetSXENum("ZCF","ZCF_CODIGO")
   Confirmsx8(.F.)
   
   If _cNum < _cNumZCF
       Processa( {|| _cNum := U_AEST051A(_cNumZCF)}, "Aguarde...","Atualizando hardlock para tabela ZCF...",.T.)
   EndIf 

   TRBZCF->(DBCloseArea())	

End Sequence 

If Select("TRBZCF") > 0
	TRBZCF->(DBCloseArea())
EndIf

FWRestArea(_aArea)

Return _cNum

/*
===============================================================================================================================
Programa----------: AEST051A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 24/05/2024
Descrição---------: Roda atualização de hardlock para o cadastro ZCF.
Parametros--------: _cUltmoCod = Ultimo código da tabela ZCF.
Retorno-----------: _cRet = Ultimo código disponível para a tabela ZCF.
===============================================================================================================================
*/
Static Function AEST051A(_cUltmoCod)
Local _cNumZCF 

Begin Sequence
   
   _cNumZCF := GetSXENum("ZCF","ZCF_CODIGO")
   Confirmsx8(.F.)
   
   While AllTrim(_cNumZCF) <= AllTrim(_cUltmoCod)
	
	   IncProc("Atualizando Hardlock -Tabela ZCF - Registro: " + AllTrim(_cNumZCF) + " de " + AllTrim(_cUltmoCod))
	
      _cNumZCF   := GetSXENum("ZCF","ZCF_CODIGO")

      Confirmsx8(.F.)
  
   EndDo

End Sequence 

Return _cNumZCF


