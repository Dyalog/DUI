$(function() {
    $.validator.setDefaults({
        ignore: [],
        errorClass: "e-validation-error",
        errorPlacement: function(error, element) {
            $(error).insertAfter(element.closest(".e-widget"));
        }
    });
})