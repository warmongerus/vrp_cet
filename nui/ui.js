$(document).ready(function() {

  // Listen for NUI Events
  window.addEventListener('message', function(event) {
      var item = event.data;

      let Toast = Swal.mixin({
        toast: true,
        position: 'center-start',
        showConfirmButton: false,
        timer: 3000
      });

      if (item.apreendidoSucesso == true) {
          Toast.fire({
              type: 'success',
              title: 'Veiculo apreendido com sucesso!'
          })
      } else if (item.removidoSucesso == true) {
        Toast.fire({
          type: 'success',
          title: 'Seu veiculo foi retirado!'
        })
      } else if (item.avisoDinheiroInsuficiente == true) {
        Toast.fire({
          type: 'error',
          title: 'Você não possui dinheiro suficiente!'
        })
      } else if (item.patioCheio == true) {
        Toast.fire({
          type: 'error',
          title: 'Pátio está lotado!'
        })
      } else if (item.naoPertence == true) {
        Toast.fire({
          type: 'error',
          title: 'Este veiculo não pertence a você!'
        })
      } else if (item.naoTemPermissao == true) {
        Toast.fire({
          type: 'error',
          title: 'Você não tem permissão!'
        })
      } else if (item.valorInvalido == true) {
        Toast.fire({
          type: 'error',
          title: 'Valor inválido!'
        })
      }
  });
});