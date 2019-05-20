var Data = new function() {
    
    this.fixformat = function(str) {
		var m = str.match(/(\d\d\d\d)-(\d\d)-(\d\d)/);
		if(m && m.length > 3)   {
			str = m[3] + '/' + m[2] + '/' + m[1];
		}
		return str;
	}
    
    this.extrairBR = function(str) {
		return str.slice(0,10);
	}
	
	this.formatUS = function(str) {
		var dt = str.split('/');
		return dt[2] + '-' + dt[1] + '-' + dt[0];
	}
    
    this.formatBR = function(data) {
      	var day = data.getDate();
	  	var month = data.getMonth() + 1;
	  	var year = data.getFullYear();
		
		if(day < 10)
			day = '0' + day;
		
		if(month < 10)
			month = '0' + month;
        
		return 	day + "/" + month + "/" + year;
	}
    
    this.formatDt = function(str) {
    	var y = str.slice(0,4);
        var m = str.slice(4,6);
        var d = str.slice(6,8);
		return d + '/' + m + '/' + y;
	}
    
    this.formatDtHr = function(str) {
        var y = str.slice(0,4);
        var m = str.slice(5,7);
        var d = str.slice(8,10);
        var h = str.slice(11,16);
		return d + '/' + m + '/' + y + ' ' + h;
    }
    
    this.formatOracle = function(str) {
		var dt = str.split('/');
		return dt[2] + dt[1] + dt[0];
	}
	
	this.dataDiaMember = function(str) {
		
		return '[Data.dia].[' +Data.fixformat(str)+']';
	}
    
    this.Diferenca = function(dtInicio, dtTermino) {
        var a = dtInicio.match(/(\d\d\d\d)-(\d\d)-(\d\d)/);
        var b = dtTermino.match(/(\d\d\d\d)-(\d\d)-(\d\d)/);
        
        var oneDay = 24 * 60 * 60 * 1000;
        var firstDate = new Date(a[1], a[2], a[3]);
        var secondDate = new Date(b[1], b[2], b[3]);
        var diffDays = Math.round(Math.abs((firstDate.getTime() - secondDate.getTime()) / (oneDay)));
        
        return diffDays;
    }
    
    this.DiferencaMes = function(dtInicio, dtTermino) {
        var a = dtTermino.match(/(\d\d\d\d)-(\d\d)-(\d\d)/);
        var b = dtInicio.match(/(\d\d\d\d)-(\d\d)-(\d\d)/);
        
        var dataUm = new Date(a[1], a[2], a[3]);
        var dataDois = new Date(b[1], b[2], b[3]);
        var dif = (dataUm.getMonth() - dataDois.getMonth()) + (12 * (dataUm.getFullYear() - dataDois.getFullYear()));
        
        return dif;
    }
	
	/*  
	Compara

	Descricao:
	Compara duas datas 

	retorna:
	menorDate <= maiorDate ( true )
	menorDate > maiorDate ( false )
	*/
    this.Compara = function (menorDate, maiorDate, separador) {
		var m = menorDate.match(/(\d\d\d\d)-(\d\d)-(\d\d)/);
		var x = maiorDate.match(/(\d\d\d\d)-(\d\d)-(\d\d)/);
		
		if(m && m.length > 3 && x && x.length > 3) {
			return menorDate <= maiorDate;
		}
		 
		var menorDt;
		var menorMt;
		var menorYr;  
		var maiorDt;
		var maiorMt;
		var maiorYr;	
		 
		 m = menorDate.match(/(\d\d?)\/(\d\d?)\/(\d\d\d\d)/);
		 x = maiorDate.match(/(\d\d?)\/(\d\d?)\/(\d\d\d\d)/);
		 if(m && m.length > 3 && x && x.length > 3) {
			 
			menorDt = parseInt( m[1] );
			menorMt = parseInt( m[2] );
			menorYr = parseInt(m[3]);  
			maiorDt = parseInt( x[1] );
			maiorMt = parseInt( x[2] );
			maiorYr = parseInt(x[3]);	
		 } else {
			 

		
			 menorDateArr = menorDate.split(separador);
			 maiorDateArr = maiorDate.split(separador);  
			 menorDt = parseInt( menorDateArr[2] );
			 menorMt = parseInt( menorDateArr[1] );
			 menorYr = menorDateArr[0];  
			 maiorDt = parseInt( maiorDateArr[2] );
			 maiorMt = parseInt( maiorDateArr[1] );
			 maiorYr = maiorDateArr[0];	
		 }
	
		if(menorYr>maiorYr) 
			return false;
		else if(menorYr==maiorYr && menorMt>maiorMt)
			return false;
		else if(menorYr==maiorYr && menorMt==maiorMt && menorDt>maiorDt)
			return false;
		else 
			return true;
	};
	
	this.Hoje = function () {
		var currentDate = new Date();
	  	var day = currentDate.getDate();
	  	var month = currentDate.getMonth() + 1;
	  	var year = currentDate.getFullYear();
		
		if(day < 10)
			day = '0' + day;
		
		if(month < 10)
			month = '0' + month;
        
		return 	day +"/"+month+"/"+year;
	}
    
    this.Hora = function() {
        var agora = new Date();
        var hora = agora.getHours();
        if(hora < 10) {
            hora = '0' + hora;
        }
        var minuto = agora.getMinutes();
        if(minuto < 10) {
            minuto = '0' + minuto;
        }
        return hora + ':' + minuto;
    }
    
    this.MesPassado = function () {
		var currentDate = new Date();
        currentDate.setMonth(currentDate.getMonth() - 1);
	  	var day = currentDate.getDate();
	  	var month = currentDate.getMonth() + 1;
	  	var year = currentDate.getFullYear();
		
		if(day < 10)
			day = '0' + day;
		
		if(month < 10)
			month = '0' + month;
        
		return 	day +"/"+month+"/"+year;
	}
    
    this.AnoPassado = function (primeiro) {
    	var currentDate = new Date();
        currentDate.setYear(currentDate.getFullYear() - 1);
	  	var day = currentDate.getDate();
	  	var month = currentDate.getMonth() + 1;
	  	var year = currentDate.getFullYear();
		
        if(primeiro) {
            day = '01'
        } else {
            if(day < 10)
            day = '0' + day;
        }
		
		if(month < 10)
			month = '0' + month;
        
		return 	day +"/"+month+"/"+year;
	}
    
    this.PrimeiroMesPassado = function () {
    	var currentDate = new Date();
        currentDate.setMonth(currentDate.getMonth() - 1);
	  	var day = currentDate.getDate();
	  	var month = currentDate.getMonth() + 1;
	  	var year = currentDate.getFullYear();
		
		if(month < 10)
			month = '0' + month;
        
		return 	"01/"+month+"/"+year;
	}
    
    this.PrimeiroAnoPassado = function () {
        var currentDate = new Date();
        currentDate.setYear(currentDate.getFullYear() - 1);
        var year = currentDate.getFullYear();
        
		return 	"01/01/"+year;
	}
    
    this.getPrimeiroMes = function () {
        var currentDate = new Date();
	  	var month = currentDate.getMonth() + 1;
	  	var year = currentDate.getFullYear();
		
		if(month < 10)
			month = '0' + month;
        
		return 	"01/"+month+"/"+year;
	}
    
    this.setNewDate = function(data) {
        var m = data.match(/(\d\d\d\d)-(\d\d)-(\d\d)/);
        var d = new Date();
        d.setFullYear(m[1]);
        d.setMonth(m[2] - 1);
        d.setDate(m[3]);
        return d;
    }
    
    this.getNewDate = function() {
        return new Date();
    }
} 