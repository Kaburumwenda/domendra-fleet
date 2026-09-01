import Swal from 'sweetalert2'

const themed = Swal.mixin({
  buttonsStyling: false,
  customClass: {
    confirmButton: 'swal-btn-confirm',
    cancelButton: 'swal-btn-cancel',
    popup: 'swal-popup',
  },
})

export default defineNuxtPlugin(() => {
  return {
    provide: {
      swal: themed,
    },
  }
})
