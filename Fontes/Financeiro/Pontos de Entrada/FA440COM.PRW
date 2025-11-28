/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |06/01/2016| Chamado 13540. Aj calc do último mês do ano na det. de data ínicio e data fim
Josué Danich  |17/12/2018| Chamado 26771. Workaround para calcular vend bloqueado
Julio Paz     |14/01/2020| Chamado 31607. Alterar rotina recalculo comissões para permitir usuário selecionar opcão Ambos.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FA440COM
Autor-------------: Josué Danich Prestes
Data da Criacao---: 27/07/2015
Descrição---------: P.E. para validar se rotina de recalculo pode rodar
Parametros--------: Nenhum
Retorno-----------: 
===============================================================================================================================
*/
User Function FN440COM()

Local _cDataF    	:= GetMv("IT_COMFECH")  // Data do fechamento
Local _nmes      	:= month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nano      	:= year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _npar5     	:= u_itGetMv("IT_FIN44005",2) // MV_PAR05 = Considera Juros    ? Sim/NÆo 
Local _npar6     	:= u_itGetMv("IT_FIN44006",1) // MV_PAR06 = Considera Descontos? Sim/NÆo   
Local _npar7     	:= u_itGetMv("IT_FIN44007",2) // MV_PAR07 = Calcula Comiss s/NCC? Sim/NÆo     
//Local _npar8     	:= u_itGetMv("IT_FIN44008",3) // MV_PAR08 = Calcular           ? Ambas/Emissao/Baixa  
Local _cPar8     	:= u_itGetMv("IT_FIN44008","13") // MV_PAR08 = Calcular           ? Ambas/Emissao/Baixa  
Local _npar9     	:= u_itGetMv("IT_FIN44009",1) // MV_PAR09 = Considera Data     ? Data Baixa/Data Disponib.  
Local _nparA     	:= u_itGetMv("IT_FIN4400A",1) // MV_PAR10 = Comis. Vend. Bloqueado ?      
Local _nparB     	:= u_itGetMv("IT_FIN4400B",1) // MV_PAR11 = Calc.Comiss.s/ RA ?           
Local _cmensagem 	:= " "
Local _aAlertas 	:= {}
Local _nI 			:= 1
Local _ddataf 	:= Date()
Local _cDataF34 	:= ""
Local _nmes34    	:= 0
Local _nano34   	:= 0

//================================================================================
//Verifica se usuário pode rodar a rotina
//================================================================================

DBSelectArea('ZZL')
ZZL->( DBSetOrder(3) )

If !(ZZL->( DBSeek( xFilial('ZZL') + RetCodUsr() ) ) .And. ZZL->ZZL_ADMCMS == 'S')

    Alert("Usuário " + AllTrim(SubStr(cUsuario,7,15)) + " sem permissão para cálculo de comissões!") 
    
    //======================================================================================
    //muda data inicial e data final para uma data impossível de modo que não rode o cálculo
    //======================================================================================
    MV_PAR01 = SToD('20010101')
    MV_PAR02 = SToD('20010101')
    Return     

End If



_dDataf := SToD(StrZero(_nano,4)+StrZero(_nmes,2)+"01")

//================================================================================
//verifica se as datas não afetam período de comissão já fechado
//================================================================================

If MV_PAR01 < _dDataF .Or.MV_PAR02 < _dDataF
  
    aAdd(_aalertas,"Período até " + DToC(_dDataF-1) + " já encerrado!")
  
End If 


//================================================================================	
//se está no gestão de fechamento de comissões força a data para o mês inteiro
//================================================================================
If AllTrim(funname()) == 'MOMS009'


 	_cDataF34 	:= ZC9->ZC9_COMP  // Data do fechamento posicionado
 	_nmes34   	:= month(SToD(SubStr(_cDataf34,4,4)+SubStr(_cDataf34,1,2)+'01'))
 	_nano34   	:= year(SToD(SubStr(_cDataf34,4,4)+SubStr(_cDataf34,1,2)+'01'))
	
	If MV_PAR01 != SToD(StrZero(_nano34,4)+StrZero(_nmes34,2)+'01')
	
		aAdd(_aalertas,"Data inicial precisa ser 01/" + StrZero(_nmes34,2) + "/" + SubStr(StrZero(_nano34,4),3,2)+ ".")
	
	EndIf
	
	If _nmes34 == 12
	
		_nmes34 := 1
		_nano34++
		
	Else
	
		_nmes34++
		
	EndIf
	
	If MV_PAR02 !=  SToD(StrZero(_nano34,4)+StrZero(_nmes34,2)+'01') - 1
	
		aAdd(_aalertas,"Data final precisa ser " + DToC(SToD(StrZero(_nano34,4)+StrZero(_nmes34,2)+'01') - 1) + ".")
	
	EndIf
	
EndIf

//================================================================================	
//verifica se usuário pode mudar parâmetros
//================================================================================

DBSelectArea('ZZL')
ZZL->( DBSetOrder(3) )

If !(ZZL->( DBSeek( xFilial('ZZL') + RetCodUsr() ) ) .And. ZZL->ZZL_RECOM == "S")

   //================================================================================
  //Verifica se perguntas estão respondidas de acordo com parâmetros
  //================================================================================

  // MV_PAR05 = Considera Juros    ? Sim/NÆo                                  
  If MV_PAR05 != _npar5
 
    If _npar5 == 1
      aAdd(_aalertas,"Considera Juros precisa ser igual a Sim")
    Else
      aAdd(_aalertas,"Considera Juros precisa ser igual a Não")
    EndIf
    
  EndIf

  // MV_PAR06 = Considera Descontos? Sim/NÆo   
  If MV_PAR06 != _npar6
 
    If _npar6 == 1
      aAdd(_aalertas,"Considera Descontos?  precisa ser igual a Sim")
    Else
      aAdd(_aalertas,"Considera Descontos?  precisa ser igual a Não")
    EndIf
    
  EndIf

  // MV_PAR07 = Calcula Comiss s/NCC? Sim/NÆo       
  If MV_PAR07 != _npar7
 
    If _npar7 == 1
      aAdd(_aalertas,"Calcula Comiss s/NCC? precisa ser igual a Sim")
    Else
      aAdd(_aalertas,"Calcula Comiss s/NCC? precisa ser igual a Não")
    EndIf
    
  EndIf

  // MV_PAR08 = Calcular ? Ambas/Emissao/Baixa   				
  If !(Str(MV_PAR08,1) $ _cPar8) 
    If "1" $ _cPar8 // _npar8 == 1
      aAdd(_aalertas,"Calcular precisa ser igual a Ambas")
    ElseIf "2" $ _cPar8 // _npar8 == 2
      aAdd(_aalertas,"Calcular precisa ser igual a Emissao")
    Else
      aAdd(_aalertas,"Calcular precisa ser igual a Baixa")
    EndIf
    
  EndIf

  // MV_PAR09 = Considera Data     ? Data Baixa/Data Disponib.    
  If MV_PAR09 != _npar9
 
    If _npar9 == 1
      aAdd(_aalertas,"Considera Data precisa ser igual a Baixa")
    Else
      aAdd(_aalertas,"Considera Data precisa ser igual a Disponib.")
    EndIf
    
  EndIf
  
  // MV_PAR10 = Comis. Vend. Bloqueado ?   
  If MV_PAR10 != _nparA
 
    If _nparA == 1
      aAdd(_aalertas,"Comis. Vend. Bloqueado ? precisa ser igual a Sim")
    Else
      aAdd(_aalertas,"Comis. Vend. Bloqueado ? precisa ser igual a Não")
    EndIf
    
  EndIf
  
  // MV_PAR09 = Considera Data     ? Data Baixa/Data Disponib.    
  If MV_PAR11 != _nparB
 
    If _nparB == 1
      aAdd(_aalertas,"Calc.Comiss.s/ RA precisa ser igual a Sim")
   Else
      aAdd(_aalertas,"Calc.Comiss.s/ RA precisa ser igual a Não")
    EndIf
    
  EndIf

EndIf

//================================================================================
//se teve qualquer alerta na verificação monta mensagem e impede o processamento
//================================================================================

If Len(_aalertas) > 0
  
    _cMensagem := "<html>"
	_cMensagem += "<body>"
	_cMensagem += "<strong>"
	_cMensagem += "<p>"
	_cMensagem += "Foram encontrados problemas com o processo!<br>"
	_cMensagem += "Recálculo não será efetuado, corrija o processo e execute novamente.<br>"
	_cMensagem += "</p>
	_cMensagem += "</strong>
	_cMensagem += "<hr>"
		
   For _nI = 1 to Len(_aalertas)
  
  		_cMensagem += "<p>"
		_cMensagem += _aalertas[_nI] 
		_cMensagem += "</p>
		If _nI < Len(_aalertas) 
		  _cMensagem += "<hr>"
		EndIf
		
	Next
	
	_cMensagem += "</body>"
	_cMensagem += "</html>"
				
	MessageBox(_cMensagem, "Problema no processo", 0)
  
    //======================================================================================
    //muda data inicial e data final para uma data impossível de modo que não rode o cálculo
    //======================================================================================
    
 	 MV_PAR01 = SToD('20010101')
   	 MV_PAR02 = SToD('20010101')
 
Else

	//================================================================================
	//se está tudo ok grava na ZC8 o log da execução com os parâmetros usados
	//================================================================================
	
	_cmensagem := "Parâmetros: " + DToC(MV_PAR01) + "|" +  DToC(MV_PAR02)
	_cmensagem += "|"+MV_PAR03+"|"+MV_PAR04+"|"+IIf(MV_PAR05==1,"Sim","Não")+"|"+IIf(MV_PAR06==1,"Sim","Não")+"|"+IIf(MV_PAR07==1,"Sim","Não")
	_cmensagem += "|"+IIf(MV_PAR08==1,"Sim","Não")+"|"+IIf(MV_PAR09==1,"Sim","Não")+"|"+IIf(MV_PAR10==1,"Sim","Não")+"|"+IIf(MV_PAR11==1,"Sim","Não")
	
	RecLock("ZC8",.T.)
 
	ZC8->ZC8_FILIAL     := xFilial("ZC8")   
	ZC8->ZC8_SEQ        := U_MOMS009C()  //Gera nova sequência do ZC8
	ZC8->ZC8_ROTINA     := "Recalculo de Comissao - Filial " + cfilant + " - " + funname()
	ZC8->ZC8_DATA       := Date()
	ZC8->ZC8_HORA       := Time()
	ZC8->ZC8_USER       := cUserName
	ZC8->ZC8_CODUSU     := __cUserId
	ZC8->ZC8_OBS        := _cmensagem
	ZC8->ZC8_COMP       := StrZero(_nmes,2) + "/" + StrZero(_nano,4)
 
	ZC8->(MSUnLock())
	
EndIf  


Return
