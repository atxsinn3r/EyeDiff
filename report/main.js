function showNotes(imageName) {
	$.getJSON('notes_data.json', function(json) {
		$(".notes")[0].innerText = json[imageName];
	});
	$(".notes-frame")[0].style.display = "inline";
};

function closeNotes() {
	$(".notes-frame")[0].style.display = "none";
};

var lastKnownIndex = -1;

function loadTargets() {
	var lastImageName;
	$.getJSON('image_data.json', function(json) {
		for (var imageName in json) {
			lastImageName = imageName;
			if (Object.keys(json).indexOf(lastImageName) <= lastKnownIndex) {
				continue;
			}
			var link1 = document.createElement('a');
			link1.setAttribute('href', "javascript:showNotes('"+ imageName +"')");
			var img1 = document.createElement('img');
			img1.setAttribute('src', 'images/' + imageName);
			var p1 = document.createElement('p');
			p1.innerText = imageName + " (MD5: "+ json[imageName] +")";
			var li1 = document.createElement('li');
			link1.appendChild(img1)
			li1.appendChild(link1);
			li1.appendChild(p1);

			var link2 = document.createElement('a');
			link2.setAttribute('href', "javascript:showNotes('"+ imageName +"')");
			var img2 = document.createElement('img');
			img2.setAttribute('src', 'images/' + imageName);
			var p2 = document.createElement('p');
			p2.innerText = imageName + " (MD5: "+ json[imageName] +")";
			var li2 = document.createElement('li');
			link2.appendChild(img2)
			li2.appendChild(link2);
			li2.appendChild(p2);

			var link3 = document.createElement('a');
			link3.setAttribute('href', "javascript:showNotes('"+ imageName +"')");
			var img3 = document.createElement('img');
			img3.setAttribute('src', 'images/' + imageName);
			var p3 = document.createElement('p');
			p3.innerText = imageName + " (MD5: "+ json[imageName] +")";
			var li3 = document.createElement('li');
			link3.appendChild(img3)
			li3.appendChild(link3);
			li3.appendChild(p3);

			$(".columns-2")[0].appendChild(li1);
			$(".columns-3")[0].appendChild(li2);
			$(".columns-4")[0].appendChild(li3);
		}

		lastKnownIndex = Object.keys(json).indexOf(lastImageName);
	});
	setTimeout(loadTargets, 3000);
}

$(document).keyup(function(e) {
     if (e.keyCode == 27) {
        closeNotes();
    }
});

$(document).ready(function() {
	$.ajaxSetup({ cache: false });
	$('.grid-nav li a').on('click', function(event){
		event.preventDefault();
		$('.grid-container').fadeOut(500, function(){
			$('#' + gridID).fadeIn(500);
		});
		var gridID = $(this).attr("data-id");
		$('.grid-nav li a').removeClass("active");
		$(this).addClass("active");
	});

	loadTargets();
});



