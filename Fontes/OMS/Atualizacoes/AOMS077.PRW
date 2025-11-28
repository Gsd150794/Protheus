/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 28/07/2017 | Ajuste no envio de campo de paletização - Chamado 20916       
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 11/06/2019 | Ajustes para loboguara - Chamado 29593           
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
=============================================================================================================================== 
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS077
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/09/2016
===============================================================================================================================
Descrição---------: Rotina de gravação dos dados do cliente no RDC -  Chamado 16681
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS077() 
Local _cQry
Local _nI 
Local _nnj := 0
Local _cEndereco, _cNumero, _cComplemento

Begin Sequence
   If ! U_ITMsg("Confirma a gravação dos dados do clientes tabela SA1, na tabela ZFH de envio de dados da integração Webservice?","Atenção",,2,2,2)
      Break
   EndIf
   
   //================================================================================
   // Monta query de dados dos clientes ativos
   //================================================================================   
   _cQry := " SELECT SA1.R_E_C_N_O_ AS NRECNO "
   _cQry += " FROM "+RetSqlName("SA1")+" SA1" 
   _cQry += " WHERE SA1.D_E_L_E_T_ = ' ' AND A1_MSBLQL = '2' "    // Não deletado e nõa bloqueado.
   
   If Select("QRYSA1") > 0
      QRYSA1->( DBCloseArea())
   EndIf
           
   _cQry := ChangeQuery(_cQry) 
   DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYSA1", .F., .T.)
   
   If QRYSA1->(Eof()) .Or. QRYSA1->(Bof())
      Break
   EndIf   
                     
   //================================================================================
   // Cria as variáveis de memória com seus respectivos incializadores padrão
   //================================================================================
   _acamps := ZFH->(Dbstruct())
   For _nnj := 1 to Len(_acamps)
      &("M->"+AllTrim(_acamps[_nnj,1])) := CriaVar(AllTrim(_acamps[_nnj,1]))
   Next

   //================================================================================
   // Monta array dos estados
   //================================================================================
 
   aUF := {}
   aAdd(aUF,{"RO","11"})
   aAdd(aUF,{"AC","12"})
   aAdd(aUF,{"AM","13"})
   aAdd(aUF,{"RR","14"})
   aAdd(aUF,{"PA","15"})
   aAdd(aUF,{"AP","16"})
   aAdd(aUF,{"TO","17"})
   aAdd(aUF,{"MA","21"})
   aAdd(aUF,{"PI","22"})
   aAdd(aUF,{"CE","23"})
   aAdd(aUF,{"RN","24"})
   aAdd(aUF,{"PB","25"})
   aAdd(aUF,{"PE","26"})
   aAdd(aUF,{"AL","27"})	
   aAdd(aUF,{"MG","31"})
   aAdd(aUF,{"ES","32"})
   aAdd(aUF,{"RJ","33"})
   aAdd(aUF,{"SP","35"})
   aAdd(aUF,{"PR","41"})
   aAdd(aUF,{"SC","42"})
   aAdd(aUF,{"RS","43"})
   aAdd(aUF,{"MS","50"})
   aAdd(aUF,{"MT","51"})
   aAdd(aUF,{"GO","52"})
   aAdd(aUF,{"DF","53"})
   aAdd(aUF,{"SE","28"})
   aAdd(aUF,{"BA","29"})
   aAdd(aUF,{"EX","99"})
	   

   //================================================================================
   // Grava os dados da tabela SA1 de clientes ativos na tabela ZFH
   //================================================================================
   QRYSA1->( DBGoTop() )
   
   While ! QRYSA1->(Eof())  
      SA1->(DBGoTo(QRYSA1->NRECNO))
                             
      //================================================================================                     
      // Os endereços de clientes abaixo estão com o nome da rua separada do numero,
      // e do complemento.                                                                               
      //================================================================================
      _cEndereco    := SA1->A1_I_END
      _cNumero      := SA1->A1_I_NUM 
      _cComplemento := SA1->A1_COMPLEM 
      If Empty(_cEndereco)
         _cEndereco    := SA1->A1_END
         _cNumero      := U_AOMS076N(SA1->A1_END)
         _cComplemento := SA1->A1_COMPLEM 
      EndIf
            
      ZFH->(RecLock("ZFH",.T.))    
      
      For _nI := 1 To ZFH->(FCount())
          &("ZFH->"+ZFH->(FieldName(_nI))) := &("M->"+ZFH->(FieldName(_nI)))      
      Next              
   
      ZFH->ZFH_FILIAL  := xFilial("ZFH")
      ZFH->ZFH_DATA    := Date()
      ZFH->ZFH_HORA    := Time()  // grava a hora de inclusão da tabela. 
      ZFH->ZFH_CGC	   := SA1->A1_CGC
      //ZFH->ZFH_COD	   := SA1->A1_I_DNRDC  // SA1->A1_COD
      ZFH->ZFH_NOME	   := SA1->A1_NOME
      ZFH->ZFH_END	   := _cEndereco  // SA1->A1_END
      ZFH->ZFH_NUMERO  := _cNumero    // U_AOMS076N(SA1->A1_END)
      ZFH->ZFH_BAIRRO  := SA1->A1_BAIRRO
      ZFH->ZFH_CMUNC   := aUF[aScan(aUF,{|x| x[1] == SA1->A1_EST})][02] + SA1->A1_COD_MUN
      ZFH->ZFH_CEP	   := SA1->A1_CEP
      
      ZFH->ZFH_ENDENT := _cEndereco
      ZFH->ZFH_NUMENT := _cNumero
      ZFH->ZFH_BAIRRE := SA1->A1_BAIRRO  // SA1->A1_BAIRROE // NAO USADO
      ZFH->ZFH_CMUEN  := aUF[aScan(aUF,{|x| x[1] == SA1->A1_EST})][02] + SA1->A1_COD_MUN // SA1->A1_CODMUNE // SA1->A1_I_CMUEN // NAO USADO
      ZFH->ZFH_CEPE   := SA1->A1_CEP     // SA1->A1_CEPE    // NAO USADO
      ZFH->ZFH_INSCR	:=	SA1->A1_INSCR  
      ZFH->ZFH_PESSOA	:=	SA1->A1_PESSOA
      ZFH->ZFH_MSBLQL	:=	"S"
      ZFH->ZFH_DDD	    :=	SA1->A1_DDD
      ZFH->ZFH_TEL	    :=	SA1->A1_TEL
      ZFH->ZFH_TIPO	:=	SA1->A1_TIPO
      ZFH->ZFH_NREDUZ	:=	SA1->A1_NREDUZ

      If SA1->A1_I_CHEP == "C"
         ZFH->ZFH_CHEP	:=	"1"  
      ElseIf SA1->A1_I_CHEP == "P"
         ZFH->ZFH_CHEP	:=	"3"  
      Else
         ZFH->ZFH_CHEP	:=	"2"  
      EndIf
                      
      If ! Empty(SA1->A1_I_GERMU)
         ZFH->ZFH_GERMU	:=	SA1->A1_I_GERMU
      EndIf
   
      If ! Empty(SA1->A1_I_DESCA)
         ZFH->ZFH_DESCA	:=	SA1->A1_I_DESCA
      EndIf
   
      If ! Empty(SA1->A1_I_TPEQP)
         ZFH->ZFH_TPEQP	:=	SA1->A1_I_TPEQP
      EndIf
      
      ZFH->ZFH_RECSA1  :=   SA1->(Recno())
      ZFH->ZFH_TXDIF   :=	SA1->A1_I_TXDIF  
      ZFH->ZFH_CODEMP  :=  '000001'
      ZFH->ZFH_USUARI  := __cUserId
      ZFH->ZFH_DATAAL  := Date()
      ZFH->(MSUnLock())
                             
      QRYSA1->(DBSkip())
   EndDo                
      
End Sequence

If Select("QRYSA1") > 0
   QRYSA1->(DBCloseArea())
EndIf             

Return
